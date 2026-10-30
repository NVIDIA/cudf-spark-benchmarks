
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_nationkey
),
SupplierPerformance AS (
    SELECT t.s_suppkey, t.s_name, o.c_nationkey, AVG(o.order_total) AS avg_order_total
    FROM TopSuppliers t
    LEFT JOIN OrderDetails o ON t.s_suppkey = o.o_orderkey  
    LEFT JOIN customer c ON o.c_nationkey = c.c_nationkey
    GROUP BY t.s_suppkey, t.s_name, o.c_nationkey
),
AggregatedPrices AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT r.r_name, sp.s_name, AVG(sp.avg_order_total) AS avg_order_total_per_supplier, ap.total_supply_cost
    FROM region r
    LEFT JOIN SupplierPerformance sp ON r.r_regionkey = sp.c_nationkey  
    LEFT JOIN AggregatedPrices ap ON sp.s_suppkey = ap.p_partkey  
    GROUP BY r.r_name, sp.s_name, ap.total_supply_cost
)
SELECT r_name, s_name, 
       COALESCE(avg_order_total_per_supplier, 0) AS avg_order_total_per_supplier,
       COALESCE(total_supply_cost, 0) AS total_supply_cost
FROM FinalReport
ORDER BY r_name, avg_order_total_per_supplier DESC;
