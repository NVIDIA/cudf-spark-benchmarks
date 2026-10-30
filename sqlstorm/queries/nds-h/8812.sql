WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, 
           RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, r.o_orderpriority
    FROM RankedOrders r
    WHERE r.rnk <= 10
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CombinedData AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment, 
           o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           s.s_name, s.s_nationkey, sd.total_supply_cost
    FROM customer c
    JOIN HighValueOrders o ON c.c_custkey = o.o_orderkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
)
SELECT cb.c_custkey, cb.c_name, cb.o_orderkey, cb.o_orderdate,
       cb.o_totalprice, s.r_name AS supplier_region, 
       cb.total_supply_cost
FROM CombinedData cb
JOIN nation n ON cb.s_nationkey = n.n_nationkey
JOIN region s ON n.n_regionkey = s.r_regionkey
WHERE cb.o_totalprice > 1000
ORDER BY cb.o_totalprice DESC, cb.o_orderdate ASC;