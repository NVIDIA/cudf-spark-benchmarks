WITH regional_sales AS (
    SELECT n.n_name AS nation_name,
           r.r_name AS region_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY n.n_name, r.r_name
),
ranked_sales AS (
    SELECT nation_name,
           region_name,
           total_sales,
           RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM regional_sales
)
SELECT r.region_name,
       COALESCE(s.nation_name, 'Unknown') AS nation_name,
       s.total_sales,
       CASE 
           WHEN s.total_sales IS NULL THEN 'No sales'
           WHEN s.sales_rank <= 5 THEN 'Top Seller'
           ELSE 'Regular Seller'
       END AS sales_category
FROM (SELECT DISTINCT region_name FROM ranked_sales) r
LEFT JOIN ranked_sales s ON r.region_name = s.region_name AND s.sales_rank <= 5
ORDER BY r.region_name, s.sales_rank;