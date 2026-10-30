WITH  regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    GROUP BY 
        r.r_name
    UNION ALL
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    WHERE 
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        r.r_name
)
SELECT 
    r.region_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    RANK() OVER (ORDER BY COALESCE(s.total_sales, 0) DESC) AS sales_rank
FROM 
    (SELECT DISTINCT r_name AS region_name FROM region) r
LEFT JOIN regional_sales s ON r.region_name = s.region_name
WHERE 
    r.region_name IS NOT NULL AND 
    (EXISTS (SELECT 1 FROM lineitem l WHERE l.l_quantity IS NOT NULL) OR 
    NOT EXISTS (SELECT 1 FROM lineitem l WHERE l.l_quantity IS NULL))
ORDER BY 
    sales_rank ASC
LIMIT 10;
