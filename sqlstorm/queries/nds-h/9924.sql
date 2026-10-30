WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        regional_sales
),
over_avg_sales AS (
    SELECT 
        region_name, 
        total_sales
    FROM 
        regional_sales
    WHERE 
        total_sales > (SELECT average_sales FROM avg_sales)
)
SELECT 
    region_name,
    total_sales,
    CASE 
        WHEN total_sales > 100000 THEN 'High Sales'
        WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    over_avg_sales
ORDER BY 
    total_sales DESC;
