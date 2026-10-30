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
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ss.total_sales) AS total_sales_by_nation
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    COALESCE(ns.total_sales_by_nation, 0) AS total_sales,
    rs.s_name,
    rs.total_sales AS supplier_sales,
    rs.sales_rank
FROM 
    NationSummary ns
LEFT JOIN 
    RankedSuppliers rs ON ns.supplier_count > 0 AND rs.sales_rank <= 5
WHERE 
    ns.total_sales_by_nation IS NOT NULL OR rs.total_sales IS NOT NULL
ORDER BY 
    ns.n_name, rs.sales_rank;