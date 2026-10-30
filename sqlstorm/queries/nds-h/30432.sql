
WITH  popular_parts AS (
    SELECT p_partkey, p_name, p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS ranking
    FROM part
    JOIN lineitem ON p_partkey = l_partkey
    JOIN orders ON o_orderkey = l_orderkey
    WHERE o_orderdate >= DATE '1997-01-01'
    GROUP BY p_partkey, p_name, p_retailprice, p_brand
),
ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
region_summary AS (
    SELECT r.r_name, COUNT(n.n_nationkey) as num_nations,
           SUM(c.c_acctbal) as total_acctbal,
           MAX(c.c_acctbal) as max_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
)
SELECT r.r_name, pp.p_name, 
       COALESCE(ps.s_name, 'Unknown Supplier') AS supplier_name, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS avg_return_revenue
FROM region_summary r
FULL OUTER JOIN popular_parts pp ON r.num_nations > 0
LEFT JOIN lineitem l ON l.l_partkey = pp.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN ranked_suppliers ps ON ps.s_suppkey = pp.p_partkey AND ps.supplier_rank = 1
GROUP BY r.r_name, pp.p_name, ps.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY r.r_name, total_revenue DESC;
