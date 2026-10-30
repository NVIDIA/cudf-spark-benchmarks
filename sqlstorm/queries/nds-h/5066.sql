WITH RegionSales AS (
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
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
), AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales 
    FROM 
        RegionSales
), TopRegions AS (
    SELECT 
        r.region, 
        r.total_sales, 
        (r.total_sales - a.avg_sales) AS sales_diff
    FROM 
        RegionSales r, 
        AvgSales a
    WHERE 
        r.total_sales > a.avg_sales
)
SELECT 
    tr.region, 
    tr.total_sales, 
    tr.sales_diff
FROM 
    TopRegions tr
ORDER BY 
    tr.sales_diff DESC
LIMIT 5;