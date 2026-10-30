
WITH  nation_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
top_sales AS (
    SELECT 
        nation_name,
        total_sales,
        CASE 
            WHEN total_sales IS NULL THEN 'Unknown'
            ELSE nation_name
        END AS sales_identifier
    FROM 
        nation_sales
    WHERE 
        sales_rank <= 5
)
SELECT 
    rs.r_name AS region,
    COALESCE(ts.nation_name, 'N/A') AS nation,
    SUM(ts.total_sales) AS total_region_sales,
    COUNT(ts.nation_name) AS number_of_nations
FROM 
    region rs
LEFT JOIN 
    nation n ON rs.r_regionkey = n.n_regionkey
LEFT JOIN 
    top_sales ts ON n.n_name = ts.sales_identifier
GROUP BY 
    rs.r_name, ts.nation_name
HAVING 
    SUM(ts.total_sales) IS NOT NULL OR COUNT(ts.nation_name) > 0
ORDER BY 
    total_region_sales DESC;
