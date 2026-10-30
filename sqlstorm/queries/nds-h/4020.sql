
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        RegionalSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM RegionalSales)
)
SELECT 
    tr.region_name,
    tr.total_sales,
    tr.order_count,
    COALESCE(NULLIF(tr.total_sales / NULLIF(tr.order_count, 0), 0), 0) AS avg_sales_per_order,
    TRIM(REGEXP_REPLACE(tr.region_name, 'Region', '')) AS cleaned_region_name
FROM 
    TopRegions tr
WHERE 
    tr.rank <= 5
UNION ALL
SELECT 
    'Other Regions' AS region_name,
    SUM(tr.total_sales) AS total_sales,
    SUM(tr.order_count) AS order_count,
    COALESCE(NULLIF(SUM(tr.total_sales) / NULLIF(SUM(tr.order_count), 0), 0), 0) AS avg_sales_per_order,
    NULL AS cleaned_region_name
FROM 
    TopRegions tr
WHERE 
    tr.rank > 5
GROUP BY 
    'Other Regions'
ORDER BY 
    total_sales DESC;
