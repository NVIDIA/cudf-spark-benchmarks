WITH  RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(CASE 
            WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS ranking
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        r.r_name
), FilteredSales AS (
    SELECT 
        region_name,
        total_sales 
    FROM 
        RegionalSales 
    WHERE 
        total_sales IS NOT NULL
)
SELECT 
    fs.region_name, 
    fs.total_sales,
    COALESCE(LEAD(fs.total_sales) OVER (ORDER BY fs.total_sales DESC), 0) - fs.total_sales AS sales_difference,
    CASE 
        WHEN fs.total_sales > (SELECT AVG(total_sales) FROM FilteredSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_category,
    CASE WHEN fs.total_sales IS NULL THEN 'No Sales' ELSE 'Has Sales' END AS sales_status
FROM 
    FilteredSales fs
FULL OUTER JOIN 
    (SELECT 
         MAX(total_sales) AS max_sales, 
         MIN(total_sales) AS min_sales
     FROM 
         FilteredSales) stats 
ON fs.total_sales = stats.max_sales
WHERE 
    (fs.total_sales > 10000 OR (fs.total_sales IS NULL AND stats.min_sales IS NOT NULL))
ORDER BY 
    fs.total_sales DESC, 
    fs.region_name ASC;