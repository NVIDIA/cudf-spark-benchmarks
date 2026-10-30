
WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey, COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice, c.c_nationkey
),
NationRegionSummary AS (
    SELECT n.n_nationkey, r.r_regionkey, r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN orders o ON n.n_nationkey = o.o_custkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY n.n_nationkey, r.r_regionkey, r.r_name
)
SELECT ss.s_suppkey, ss.s_name, os.o_orderkey, os.o_totalprice, nrs.r_name, nrs.order_count, ss.total_available, ss.avg_cost
FROM SupplierStats ss
JOIN OrderSummary os ON os.lineitem_count > 10
JOIN NationRegionSummary nrs ON nrs.order_count > 5
WHERE ss.total_available > 1000
ORDER BY nrs.order_count DESC, ss.avg_cost ASC;
