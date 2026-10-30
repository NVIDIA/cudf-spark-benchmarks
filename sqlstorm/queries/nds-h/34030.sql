WITH  regional_sales AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate <= DATE '1996-12-31'
    GROUP BY 
        n.n_nationkey, r.r_regionkey
),
top_sales AS (
    SELECT 
        r.r_name,
        n.n_name,
        rs.total_sales
    FROM 
        regional_sales rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON rs.r_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 3
),
null_sales AS (
    SELECT 
        r.r_name AS region,
        COALESCE(SUM(ts.total_sales), 0) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        top_sales ts ON ts.r_name = r.r_name
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region,
    COALESCE(ns.total_sales, 0) AS total_sales
FROM 
    region r
LEFT JOIN 
    null_sales ns ON r.r_name = ns.region
WHERE 
    ns.total_sales IS NULL 
    OR ns.total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;