WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS total_sales_by_nation,
        COUNT(DISTINCT ss.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        SupplierSales ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    ns.total_sales_by_nation,
    ns.supplier_count,
    r.r_name,
    r.r_comment
FROM 
    NationSummary ns
JOIN 
    nation n ON ns.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ns.total_sales_by_nation > (
        SELECT AVG(total_sales_by_nation) FROM NationSummary
    )
ORDER BY 
    ns.total_sales_by_nation DESC;
