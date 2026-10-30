WITH  RegionSales AS (
    SELECT 
        r.r_name,
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
        l.l_shipdate BETWEEN DATE '1997-01-01' AND cast('1998-10-01' as date)
    GROUP BY 
        r.r_name
    
    UNION ALL
    
    SELECT 
        r.r_name,
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
        l.l_shipdate BETWEEN DATE '1997-01-01' AND cast('1998-10-01' as date)
    AND
        o.o_orderpriority = 'HIGH'
    GROUP BY 
        r.r_name
),
FilteredSales AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(total_sales), 0) AS total_sales
    FROM 
        RegionSales r
    GROUP BY 
        r.r_name
)
SELECT 
    f.r_name,
    f.total_sales,
    CASE 
        WHEN f.total_sales IS NULL THEN 'No Sales'
        WHEN f.total_sales > 1000000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM 
    FilteredSales f
LEFT JOIN 
    region r ON f.r_name = r.r_name
ORDER BY 
    f.total_sales DESC;