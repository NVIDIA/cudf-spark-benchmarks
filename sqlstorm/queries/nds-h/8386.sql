WITH regional_sales AS (
    SELECT 
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        regional_sales
)
SELECT 
    region,
    total_sales,
    CASE 
        WHEN total_sales > (SELECT average_sales FROM avg_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_status
FROM 
    regional_sales
ORDER BY 
    total_sales DESC;
