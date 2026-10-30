WITH  nation_sales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name, n.n_nationkey
),
ranked_sales AS (
    SELECT 
        n_name,
        total_sales,
        sales_rank,
        MAX(total_sales) OVER () AS max_sales
    FROM 
        nation_sales
)
SELECT 
    n.n_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    CASE 
        WHEN r.sales_rank IS NULL THEN '0'
        ELSE CAST(r.sales_rank AS STRING)
    END AS sales_rank,
    r.max_sales,
    CASE 
        WHEN r.max_sales > 0 THEN 
            (COALESCE(r.total_sales, 0) * 100.0 / r.max_sales)
        ELSE 
            NULL 
    END AS sales_percentage
FROM 
    nation n
LEFT JOIN 
    ranked_sales r ON n.n_name = r.n_name
WHERE 
    n.n_name IS NOT NULL
ORDER BY 
    total_sales DESC, n.n_name;

