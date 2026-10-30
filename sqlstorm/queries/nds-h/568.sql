WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(ss.total_sales) AS total_nation_sales
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        n.n_name,
        ns.total_nation_sales,
        RANK() OVER (ORDER BY ns.total_nation_sales DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        NationSales ns ON n.n_name = ns.n_name
)
SELECT 
    t.n_name,
    t.total_nation_sales,
    CASE 
        WHEN t.sales_rank <= 5 THEN 'Top Nation'
        WHEN t.sales_rank BETWEEN 6 AND 10 THEN 'Mid Nation'
        ELSE 'Other Nation'
    END AS nation_category
FROM 
    TopNations t
WHERE 
    t.total_nation_sales IS NOT NULL
ORDER BY 
    t.sales_rank;