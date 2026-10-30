WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        customer_count,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
TotalSales AS (
    SELECT 
        SUM(total_sales) AS global_sales
    FROM 
        RankedSales
)

SELECT 
    r.region_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.customer_count, 0) AS customer_count,
    COALESCE(r.order_count, 0) AS order_count,
    CASE 
        WHEN r.sales_rank IS NULL THEN 'Unranked'
        ELSE CAST(r.sales_rank AS STRING)
    END AS sales_rank,
    (SELECT global_sales FROM TotalSales) - 
    COALESCE(r.total_sales, 0) AS sales_difference,
    CASE 
        WHEN r.total_sales IS NULL AND r.customer_count IS NULL 
        THEN 'No sales data'
        WHEN r.total_sales IS NOT NULL AND r.customer_count IS NULL 
        THEN 'Sales data without customers'
        WHEN r.total_sales IS NULL AND r.customer_count IS NOT NULL 
        THEN 'Customers without sales data'
        ELSE 'Regular sales data'
    END AS sales_description
FROM 
    RankedSales r
FULL OUTER JOIN 
    region rg ON r.region_name = rg.r_name
ORDER BY 
    region_name NULLS LAST;
