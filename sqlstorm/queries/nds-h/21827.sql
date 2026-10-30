
WITH RegionSales AS (
    SELECT n.n_name AS nation_name, 
           r.r_name AS region_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY n.n_name, r.r_name, r.r_regionkey
)

SELECT 
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales' 
        ELSE CONCAT('Total Sales: ', CAST(total_sales AS VARCHAR(20)), 
                    ' - Order Count: ', CAST(order_count AS VARCHAR(20)), 
                    ' - Rank: ', CAST(sales_rank AS VARCHAR(20))) 
    END AS sales_summary,
    rg.r_comment AS region_comment
FROM RegionSales r
LEFT OUTER JOIN region rg ON r.region_name = rg.r_name
WHERE r.sales_rank <= 3 OR r.sales_rank IS NULL

UNION ALL

SELECT 
    'Out of Rank' AS sales_summary, 
    COALESCE(rg.r_comment, 'No Region Comment') 
FROM region rg
WHERE NOT EXISTS (
    SELECT 1 
    FROM RegionSales r 
    WHERE rg.r_name = r.region_name
    AND r.sales_rank IS NOT NULL
)
ORDER BY sales_summary;
