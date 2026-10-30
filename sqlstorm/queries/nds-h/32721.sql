WITH  region_sales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY r.r_regionkey, r.r_name
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1998-01-01' AND l.l_shipdate < DATE '2025-01-01'
    GROUP BY r.r_regionkey, r.r_name
),
ranked_sales AS (
    SELECT r.r_name, r.total_sales,
           RANK() OVER (PARTITION BY r.r_regionkey ORDER BY r.total_sales DESC) AS sales_rank
    FROM region_sales r
),
final_sales AS (
    SELECT r.r_name, 
           COALESCE(r.total_sales, 0) AS total_sales,
           CASE 
               WHEN r.total_sales IS NULL THEN 'No Sales'
               ELSE 'Sales Made'
           END AS sale_status
    FROM ranked_sales r
)

SELECT f.r_name, f.total_sales, f.sale_status
FROM final_sales f
WHERE f.total_sales > 0
ORDER BY f.total_sales DESC
LIMIT 10;