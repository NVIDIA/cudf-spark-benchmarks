WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales,
        COUNT(ss.order_count) AS total_orders
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_name
),
SalesRanked AS (
    SELECT 
        r.r_name,
        r.region_total_sales,
        RANK() OVER (ORDER BY r.region_total_sales DESC) AS sales_rank
    FROM 
        RegionSales r
)
SELECT 
    r.r_name,
    COALESCE(r.region_total_sales, 0) AS total_sales,
    r.sales_rank,
    CASE WHEN r.region_total_sales IS NULL THEN 'No Sales' ELSE 'Sales Exist' END AS sales_status
FROM 
    SalesRanked r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.sales_rank;
