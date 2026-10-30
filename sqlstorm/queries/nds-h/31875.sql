WITH  RegionSales AS (
    SELECT 
        r.r_name AS region_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
FilteredSales AS (
    SELECT 
        region_name, 
        total_sales
    FROM 
        RegionSales
    WHERE 
        total_sales > (
            SELECT AVG(total_sales) FROM RegionSales
        )
)
SELECT 
    f.region_name, 
    f.total_sales, 
    COALESCE((
        SELECT COUNT(DISTINCT c.c_custkey) 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    ), 0) AS active_customers,
    CASE 
        WHEN f.total_sales >= 100000 THEN 'High'
        WHEN f.total_sales >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    FilteredSales f
ORDER BY 
    f.total_sales DESC;