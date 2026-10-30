WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND l.l_discount > 0.05
    GROUP BY 
        r.r_name
),
FilteredSales AS (
    SELECT 
        r.region_name,
        r.total_sales,
        r.order_count
    FROM 
        RegionalSales r
    WHERE 
        r.total_sales > (SELECT AVG(total_sales) FROM RegionalSales)
)
SELECT 
    fs.region_name,
    COALESCE(fs.total_sales, 0) AS sales_amount,
    fs.order_count,
    CASE 
        WHEN fs.order_count > 100 THEN 'High Activity'
        WHEN fs.order_count > 50 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS activity_level,
    (fs.total_sales / NULLIF(fs.order_count, 0)) AS average_order_value
FROM 
    FilteredSales fs
FULL OUTER JOIN 
    region r ON fs.region_name = r.r_name
WHERE 
    r.r_name IS NOT NULL OR fs.region_name IS NULL
ORDER BY 
    COALESCE(fs.total_sales, 0) DESC, 
    fs.order_count ASC;