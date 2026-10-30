WITH regional_sales AS (
    SELECT 
        r.r_name AS region,
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
yearly_growth AS (
    SELECT 
        region,
        total_sales,
        LAG(total_sales) OVER (ORDER BY region) AS previous_year_sales,
        (total_sales - LAG(total_sales) OVER (ORDER BY region)) / NULLIF(LAG(total_sales) OVER (ORDER BY region), 0) * 100 AS growth_percentage
    FROM 
        regional_sales
)
SELECT 
    region,
    total_sales,
    COALESCE(previous_year_sales, 0) AS previous_year_sales,
    COALESCE(growth_percentage, 0) AS growth_percentage
FROM 
    yearly_growth
ORDER BY 
    region;