
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_order_count
    FROM 
        RegionalSales
)
SELECT 
    rs.region_name,
    rs.total_sales,
    rs.order_count,
    (rs.total_sales - avg.avg_sales) / NULLIF(avg.avg_sales, 0) * 100 AS sales_variance_percentage,
    (rs.order_count - avg.avg_order_count) / NULLIF(avg.avg_order_count, 0) * 100 AS order_count_variance_percentage
FROM 
    RegionalSales rs
CROSS JOIN 
    AverageSales avg
ORDER BY 
    rs.total_sales DESC;
