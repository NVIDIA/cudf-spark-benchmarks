
WITH  avg_order_value AS (
    SELECT o_custkey, AVG(o_totalprice) AS avg_value
    FROM orders
    GROUP BY o_custkey
),
supplier_region AS (
    SELECT s.s_suppkey, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
distinct_part_types AS (
    SELECT DISTINCT p_type
    FROM part
),
order_summary AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
)

SELECT sr.nation_name, sr.region_name, p.p_type, SUM(os.total_revenue) AS total_revenue,
       COALESCE(AVG(a.avg_value), 0) AS avg_order_value,
       (SELECT COUNT(*) FROM distinct_part_types) AS unique_part_types_count
FROM supplier_region sr
LEFT JOIN partsupp ps ON sr.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN order_summary os ON sr.s_suppkey = os.c_custkey
LEFT JOIN avg_order_value a ON os.c_custkey = a.o_custkey
WHERE p.p_retailprice > 100.00
  AND os.revenue_rank = 1
GROUP BY sr.nation_name, sr.region_name, p.p_type
ORDER BY total_revenue DESC
LIMIT 5;
