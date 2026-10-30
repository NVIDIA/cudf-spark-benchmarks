WITH  regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
ordered_sales AS (
    SELECT 
        region_name,
        total_sales,
        sales_rank,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        regional_sales
)
SELECT 
    o.region_name,
    COALESCE(o.total_sales, 0) AS total_sales,
    CASE 
        WHEN o.sales_quartile = 1 THEN 'Top Sales'
        WHEN o.sales_quartile = 2 THEN 'Upper Middle Sales'
        WHEN o.sales_quartile = 3 THEN 'Lower Middle Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    ordered_sales o
FULL OUTER JOIN 
    (SELECT 
         r.r_name AS region_name,
         COUNT(DISTINCT n.n_nationkey) AS nation_count
     FROM 
         region r
     LEFT JOIN 
         nation n ON r.r_regionkey = n.n_regionkey
     GROUP BY 
         r.r_name) r_count ON o.region_name = r_count.region_name
WHERE 
    (o.total_sales IS NOT NULL OR r_count.nation_count IS NOT NULL)
ORDER BY 
    o.total_sales DESC NULLS LAST;
