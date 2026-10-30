
WITH RegionalSales AS (
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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
        AND l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
SalesStatistics AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        AVG(total_sales) OVER () AS average_sales,
        MIN(total_sales) OVER () AS min_sales,
        MAX(total_sales) OVER () AS max_sales,
        STDDEV(total_sales) OVER () AS stddev_sales
    FROM 
        RegionalSales
)
SELECT 
    region_name,
    total_sales,
    order_count,
    total_sales - average_sales AS sales_variance,
    (total_sales - average_sales) / NULLIF(stddev_sales, 0) AS z_score
FROM 
    SalesStatistics
ORDER BY 
    total_sales DESC;
