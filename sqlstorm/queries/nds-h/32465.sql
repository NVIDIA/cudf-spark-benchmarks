WITH  nation_sales AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_name
),
sales_ranked AS (
    SELECT 
        n_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        nation_sales
),
filtered_sales AS (
    SELECT 
        n.n_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' 
        AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        n.n_name
)
SELECT 
    f.n_name,
    f.net_sales,
    CASE 
        WHEN f.net_sales > 100000 THEN 'High'
        WHEN f.net_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category,
    sr.sales_rank
FROM 
    filtered_sales f
LEFT JOIN 
    sales_ranked sr ON f.n_name = sr.n_name
WHERE 
    f.net_sales > 0
ORDER BY 
    f.net_sales DESC, 
    sr.sales_rank ASC
LIMIT 10;