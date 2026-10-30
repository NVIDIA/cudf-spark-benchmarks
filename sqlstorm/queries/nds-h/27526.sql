WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           REPLACE(LOWER(s.s_name), ' ', '-') AS normalized_name,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
),
part_info AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_comment,
           CONCAT(LEFT(p.p_name, 10), '...', RIGHT(p.p_name, 5)) AS abbreviated_name
    FROM part p
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_orders AS (
    SELECT o.o_orderkey, c.c_name, c.c_mktsegment,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(o.o_orderkey) AS order_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name, c.c_mktsegment
)
SELECT 
    s.normalized_name,
    SUM(pi.p_retailprice) AS total_part_value,
    cn.n_name AS nation_name,
    SUM(co.total_sales) AS total_sales,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    AVG(s.comment_length) AS avg_comment_length
FROM supplier_info s
JOIN part_info pi ON s.s_suppkey = pi.p_partkey
JOIN nation_info cn ON s.s_nationkey = cn.n_nationkey
JOIN customer_orders co ON s.s_suppkey = co.o_orderkey
WHERE s.s_acctbal > 1000
  AND s.s_comment LIKE '%reliable%'
GROUP BY s.normalized_name, cn.n_name
ORDER BY total_sales DESC, avg_comment_length ASC;
