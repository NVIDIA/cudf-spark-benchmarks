
WITH SupplierAggregates AS (
    SELECT s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(sa.total_cost) AS region_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierAggregates sa ON n.n_nationkey = sa.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY region_cost DESC
    LIMIT 10
)
SELECT tr.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM TopRegions tr
JOIN nation n ON tr.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
GROUP BY tr.r_name
ORDER BY revenue DESC;
