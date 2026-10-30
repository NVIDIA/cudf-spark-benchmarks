WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT * 
    FROM RankedSuppliers 
    WHERE supply_rank <= 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_order_value) AS total_spend, COUNT(os.o_orderkey) AS order_count
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT co.c_custkey, co.c_name, co.total_spend, co.order_count, COUNT(ts.s_suppkey) AS top_supplier_count
    FROM CustomerOrderStats co
    LEFT JOIN TopSuppliers ts ON co.c_custkey = ts.s_suppkey
    GROUP BY co.c_custkey, co.c_name, co.total_spend, co.order_count
)
SELECT f.c_custkey, f.c_name, f.total_spend, f.order_count, f.top_supplier_count 
FROM FinalReport f
WHERE f.total_spend > (SELECT AVG(total_spend) FROM CustomerOrderStats)
ORDER BY f.total_spend DESC;
