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
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) as sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_sales > 100000
)
SELECT 
    ns.n_name AS nation, 
    rs.r_name AS region, 
    COUNT(ts.s_suppkey) AS number_of_top_suppliers
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region rs ON ns.n_regionkey = rs.r_regionkey
GROUP BY 
    ns.n_name, rs.r_name
ORDER BY 
    number_of_top_suppliers DESC, rs.r_name ASC;