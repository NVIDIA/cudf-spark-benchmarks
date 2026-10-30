WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierSales ss ON n.n_nationkey = ss.s_suppkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    rs.region_total_sales,
    ROW_NUMBER() OVER (ORDER BY rs.region_total_sales DESC) AS sales_rank
FROM 
    RegionSales rs
JOIN 
    region r ON r.r_regionkey = rs.n_regionkey
WHERE 
    rs.region_total_sales > (
        SELECT 
            AVG(region_total_sales)
        FROM 
            RegionSales
    )
UNION ALL
SELECT 
    'Total' AS region_name,
    SUM(region_total_sales) AS region_total_sales,
    NULL
FROM 
    RegionSales
ORDER BY 
    sales_rank NULLS LAST;
