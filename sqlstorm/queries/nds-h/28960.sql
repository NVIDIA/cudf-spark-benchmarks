WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name,
           SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier AS s
    JOIN nation AS n ON s.s_nationkey = n.n_nationkey
), PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container,
           CONCAT(p.p_name, ' (', p.p_brand, ')') AS part_description,
           CASE 
               WHEN p.p_size < 10 THEN 'Small'
               WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
               ELSE 'Large'
           END AS size_category
    FROM part AS p
), Combined AS (
    SELECT si.s_name, si.nation_name, pi.part_description, pi.size_category,
           COUNT(l.l_orderkey) AS total_orders,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM SupplierInfo AS si
    JOIN partsupp AS ps ON si.s_suppkey = ps.ps_suppkey
    JOIN lineitem AS l ON ps.ps_partkey = l.l_partkey
    JOIN PartInfo AS pi ON l.l_partkey = pi.p_partkey
    GROUP BY si.s_name, si.nation_name, pi.part_description, pi.size_category
)
SELECT nation_name, size_category, COUNT(DISTINCT s_name) AS supplier_count,
       SUM(total_orders) AS total_orders, SUM(total_revenue) AS revenue
FROM Combined
GROUP BY nation_name, size_category
ORDER BY revenue DESC, supplier_count DESC;
