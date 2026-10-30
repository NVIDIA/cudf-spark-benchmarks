WITH RegionSales AS (
    SELECT 
        r.r_name,
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
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
),
RankedSales AS (
    SELECT 
        r.r_name,
        rs.total_sales,
        rs.order_count,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RegionSales rs
    JOIN 
        region r ON rs.r_name = r.r_name
)
SELECT 
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'No Sales Data'
        ELSE CAST(rs.sales_rank AS VARCHAR(5))
    END AS sales_rank
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_name = rs.r_name
WHERE 
    r.r_comment IS NOT NULL 
    AND (rs.total_sales > (SELECT AVG(total_sales) FROM RegionSales) OR rs.order_count = 0)
ORDER BY 
    r.r_name;
