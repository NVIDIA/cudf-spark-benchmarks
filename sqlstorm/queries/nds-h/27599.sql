WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name,
           CONCAT(s.s_name, ' from ', n.n_name, ', ', r.r_name) AS supplier_location
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
part_info AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type,
           CASE 
               WHEN p.p_size > 30 THEN 'Large'
               WHEN p.p_size BETWEEN 15 AND 30 THEN 'Medium'
               ELSE 'Small'
           END AS size_category
    FROM part p
),
combined_info AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, si.supplier_location, pi.p_name, pi.size_category,
           COUNT(o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice) AS total_extended_price
    FROM partsupp ps
    JOIN supplier_info si ON ps.ps_suppkey = si.s_suppkey
    JOIN part_info pi ON ps.ps_partkey = pi.p_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, si.supplier_location, pi.p_name, pi.size_category
)
SELECT size_category, COUNT(*) AS supplier_count, SUM(order_count) AS total_orders,
       SUM(total_extended_price) AS total_revenue
FROM combined_info
GROUP BY size_category
ORDER BY supplier_count DESC, total_revenue DESC;
