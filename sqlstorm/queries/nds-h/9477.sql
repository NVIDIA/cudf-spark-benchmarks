WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
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
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        r.r_name
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales 
    FROM 
        RegionalSales
),
TopRegions AS (
    SELECT 
        region, 
        total_sales, 
        total_sales - (SELECT avg_sales FROM AverageSales) AS sales_variance
    FROM 
        RegionalSales
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    region, 
    total_sales, 
    sales_variance
FROM 
    TopRegions;