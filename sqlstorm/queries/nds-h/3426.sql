
WITH RegionalSales AS (
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
    GROUP BY 
        r.r_name
),
CumulativeSales AS (
    SELECT 
        region_name,
        total_sales,
        SUM(total_sales) OVER (ORDER BY total_sales DESC) AS cumulative_sales
    FROM 
        RegionalSales
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        cumulative_sales
    FROM 
        CumulativeSales
    WHERE 
        cumulative_sales <= (SELECT AVG(cumulative_sales) FROM CumulativeSales)
)
SELECT 
    tr.region_name,
    COALESCE(tr.total_sales, 0) AS total_sales,
    COALESCE(tr.cumulative_sales, 0) AS cumulative_sales,
    (SELECT COUNT(*) 
     FROM customer c 
     WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    ) AS customer_count_USA
FROM 
    TopRegions tr
LEFT JOIN 
    orders o ON tr.total_sales > (SELECT AVG(total_sales) FROM TopRegions)
WHERE 
    tr.total_sales > 10000
ORDER BY 
    tr.total_sales DESC;
