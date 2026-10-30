WITH  RegionalSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(o.o_totalprice) AS total_sales
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
        lineitem l ON l.l_partkey = p.p_partkey 
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        r.r_regionkey, r.r_name 
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_sales
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
        lineitem l ON l.l_partkey = p.p_partkey 
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    WHERE 
        o.o_orderstatus = 'O' 
        AND EXISTS (
            SELECT 1 
            FROM orders o2 
            WHERE o2.o_custkey = o.o_custkey 
            AND o2.o_totalprice > o.o_totalprice
        )
    GROUP BY 
        r.r_regionkey, r.r_name
),
SalesRanked AS (
    SELECT 
        r.r_name,
        r.total_sales,
        RANK() OVER (ORDER BY r.total_sales DESC) as sales_rank
    FROM 
        RegionalSales r
)
SELECT 
    sr.r_name,
    sr.total_sales,
    CASE 
        WHEN sr.sales_rank <= 5 THEN 'Top 5 Region'
        ELSE 'Other Region'
    END AS region_category,
    COALESCE(n.n_comment, 'No comment') AS nation_comment,
    CASE 
        WHEN sr.total_sales IS NULL THEN 'Sales data missing'
        ELSE 'Sales data available'
    END AS sales_data_status
FROM 
    SalesRanked sr
LEFT JOIN 
    nation n ON sr.r_name = n.n_name
WHERE 
    sr.total_sales > 10000
ORDER BY 
    sr.sales_rank;
