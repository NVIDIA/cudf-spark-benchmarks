WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(l.l_quantity) AS avg_quantity,
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
RegionalSales AS (
    SELECT 
        n.n_name AS region_name,
        SUM(ss.total_sales) AS region_total_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    r.r_comment,
    COALESCE(rs.region_total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(rs.region_total_sales, 0) > 100000 THEN 'High'
        WHEN COALESCE(rs.region_total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    RegionalSales rs ON r.r_name = rs.region_name
ORDER BY 
    total_sales DESC
LIMIT 10;
