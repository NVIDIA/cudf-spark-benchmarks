WITH RegionalSales AS (
    SELECT 
        r_name AS region_name,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        COUNT(DISTINCT o_orderkey) AS order_count,
        AVG(l_quantity) AS avg_quantity
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
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        r_name
), AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_total_sales 
    FROM 
        RegionalSales
)
SELECT 
    region_name,
    total_sales,
    order_count,
    avg_quantity,
    CASE 
        WHEN total_sales > (SELECT avg_total_sales FROM AvgSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    RegionalSales
ORDER BY 
    total_sales DESC;