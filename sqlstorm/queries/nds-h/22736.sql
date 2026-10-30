
WITH regional_sales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), aggregated_data AS (
    SELECT 
        region,
        total_sales,
        order_count,
        sales_rank,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales' 
            WHEN order_count = 0 THEN 'No Orders' 
            ELSE 'Sales Data Available' 
        END AS sales_status
    FROM 
        regional_sales
), filtered_sales AS (
    SELECT 
        region, 
        total_sales, 
        order_count, 
        sales_rank, 
        sales_status
    FROM 
        aggregated_data 
    WHERE 
        sales_rank <= 3 OR sales_status = 'No Sales'
)
SELECT 
    f.region,
    f.total_sales,
    f.order_count,
    f.sales_status,
    CONCAT('Region: ', f.region, ' | Total Sales: ', COALESCE(CAST(f.total_sales AS STRING), 'N/A'), ' | Order Count: ', COALESCE(CAST(f.order_count AS STRING), 'N/A'), ' | Status: ', f.sales_status) AS sales_report
FROM 
    filtered_sales f
FULL OUTER JOIN 
    (SELECT DISTINCT r.r_name FROM region r) r ON f.region = r.r_name
ORDER BY 
    COALESCE(f.total_sales, 0) DESC, 
    f.region;
