WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
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
        lineitem l ON l.l_partkey = p.p_partkey
    LEFT JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < DATE '1997-10-01'
        AND p.p_brand IN ('BrandA', 'BrandB')
    GROUP BY 
        r.r_name
), RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    rs.region_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    CASE 
        WHEN rs.sales_rank <= 10 THEN 'Top Sales Region'
        ELSE 'Other Region'
    END AS sales_category
FROM 
    RankedSales rs
FULL OUTER JOIN 
    region r ON r.r_name = rs.region_name
ORDER BY 
    region_name;