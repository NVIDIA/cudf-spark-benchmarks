
WITH  recursive_supplier AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
products_with_comments AS (
    SELECT p_partkey, p_name, 
           CASE 
               WHEN p_comment IS NULL THEN 'No comment available'
               WHEN LENGTH(p_comment) < 1 THEN 'Empty comment'
               ELSE p_comment 
           END AS p_comment_processed,
           p_retailprice * (1 - AVG(l_discount) OVER (PARTITION BY l_partkey)) AS effective_price
    FROM part
    LEFT JOIN lineitem ON part.p_partkey = lineitem.l_partkey
),
filtered_orders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderpriority,
           CASE WHEN o_orderstatus = 'F' THEN 'Finished' ELSE 'Not Finished' END AS order_status_label,
           RANK() OVER (PARTITION BY o_orderstatus ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
)
SELECT r.r_name, COALESCE(ps.ps_availqty, 0) AS available_quantity, 
       SUM(p.effective_price) AS total_retail_value,
       ARRAY_AGG(DISTINCT CONCAT(s.s_name, ': ', p.p_name)) AS supplier_product_list
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN recursive_supplier s ON n.n_nationkey = s.s_nationkey AND s.rank <= 5
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN products_with_comments p ON ps.ps_partkey = p.p_partkey
LEFT JOIN filtered_orders o ON o.o_custkey = s.s_suppkey
WHERE (s.s_acctbal > 1000 OR s.s_name LIKE 'A%')
  AND (r.r_name LIKE '%west%' OR NULLIF(n.n_name, '') IS NOT NULL)
GROUP BY r.r_name, ps.ps_availqty
HAVING SUM(p.effective_price) > 5000 AND COUNT(s.s_suppkey) > 2
ORDER BY total_retail_value DESC NULLS LAST;
