WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT s.*, RANK() OVER (ORDER BY total_supply_value DESC) AS supplier_rank
    FROM RankedSuppliers s
    WHERE s.total_supply_value > (SELECT AVG(total_supply_value) FROM RankedSuppliers)
),
RelevantOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, l.l_suppkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT n.n_name, COUNT(DISTINCT ro.o_orderkey) AS order_count, SUM(ro.o_totalprice) AS total_revenue
FROM RelevantOrders ro
JOIN supplier s ON ro.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
