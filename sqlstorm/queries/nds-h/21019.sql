WITH regional_sales AS (
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
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
        AND l.l_discount BETWEEN 0.0 AND 0.1
    GROUP BY 
        r.r_name
),
nations_with_sales AS (
    SELECT 
        n.n_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.order_count, 0) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        regional_sales rs ON n.n_name = rs.region_name
)
SELECT 
    n.n_name,
    n.total_sales,
    n.order_count,
    CASE 
        WHEN n.total_sales > 10000 THEN 'High Value'
        WHEN n.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    nations_with_sales n
WHERE 
    (n.total_sales IS NOT NULL OR n.order_count > 0)
ORDER BY 
    sales_category DESC, n.total_sales DESC
LIMIT 10;