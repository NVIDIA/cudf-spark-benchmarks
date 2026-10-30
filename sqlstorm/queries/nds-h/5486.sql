WITH regional_sales AS (
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
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
        AND o.o_orderstatus = 'F'
    GROUP BY 
        r.r_name
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        regional_sales
),
above_average_sales AS (
    SELECT 
        region_name, total_sales
    FROM 
        regional_sales
    WHERE 
        total_sales > (SELECT avg_sales FROM average_sales)
)
SELECT 
    region_name,
    total_sales,
    (CASE WHEN total_sales IS NOT NULL THEN total_sales * 0.1 ELSE 0 END) AS bonus
FROM 
    above_average_sales
ORDER BY 
    total_sales DESC;
