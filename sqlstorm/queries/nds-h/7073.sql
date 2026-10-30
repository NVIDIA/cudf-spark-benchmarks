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
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(ss.total_sales) AS total_nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.total_nation_sales,
    RANK() OVER (ORDER BY ns.total_nation_sales DESC) AS sales_rank
FROM 
    NationSales ns
WHERE 
    ns.total_nation_sales > 1000000
ORDER BY 
    ns.total_nation_sales DESC;