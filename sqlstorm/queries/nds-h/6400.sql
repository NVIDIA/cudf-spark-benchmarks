WITH region_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales_value
    FROM 
        region_sales
),
best_region AS (
    SELECT 
        region_name
    FROM 
        region_sales
    WHERE 
        total_sales = (SELECT MAX(total_sales) FROM region_sales)
)
SELECT 
    r.region_name,
    rs.total_sales,
    asv.avg_sales_value
FROM 
    region_sales rs
JOIN 
    best_region r ON r.region_name = rs.region_name
CROSS JOIN 
    avg_sales asv
WHERE 
    rs.total_sales > asv.avg_sales_value
ORDER BY 
    rs.total_sales DESC;
