WITH RegionalSales AS (
    SELECT 
        r_name AS region,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM 
        lineitem 
    JOIN 
        orders ON l_orderkey = o_orderkey
    JOIN 
        customer ON o_custkey = c_custkey
    JOIN 
        supplier ON c_nationkey = s_nationkey
    JOIN 
        nation ON s_nationkey = n_nationkey
    JOIN 
        region ON n_regionkey = r_regionkey
    WHERE 
        l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1998-01-01'
    GROUP BY 
        r_name
),
TopRegions AS (
    SELECT 
        region,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    region,
    total_sales
FROM 
    TopRegions
WHERE 
    sales_rank <= 5
ORDER BY 
    total_sales DESC;