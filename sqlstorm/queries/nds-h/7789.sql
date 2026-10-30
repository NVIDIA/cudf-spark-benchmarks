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
        l.l_shipdate >= DATE '1995-01-01' AND 
        l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sales.total_sales
    FROM 
        SupplierSales sales
    JOIN 
        supplier s ON sales.s_suppkey = s.s_suppkey
    ORDER BY 
        sales.total_sales DESC
    LIMIT 10
)
SELECT 
    t.s_suppkey,
    t.s_name,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    t.total_sales
FROM 
    TopSuppliers t
JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    t.total_sales DESC;
