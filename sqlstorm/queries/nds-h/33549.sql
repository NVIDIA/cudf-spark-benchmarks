
WITH  cte_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000.00
),
cte_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
cte_part_sales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
ranked_parts AS (
    SELECT ps.p_partkey, ps.part_revenue,
           RANK() OVER (ORDER BY ps.part_revenue DESC) AS part_rank
    FROM cte_part_sales ps
)
SELECT r.r_name, c.c_mktsegment, 
       COALESCE(SUM(o.total_lineitem_price), 0) AS total_order_value,
       COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
       AVG(CASE WHEN p.part_rank <= 10 THEN p.part_revenue ELSE NULL END) AS avg_top_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN cte_orders o ON c.c_custkey = o.o_orderkey
LEFT JOIN cte_supplier ss ON ss.s_suppkey = o.o_orderkey
LEFT JOIN ranked_parts p ON p.p_partkey = o.o_orderkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, c.c_mktsegment
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY total_order_value DESC;
