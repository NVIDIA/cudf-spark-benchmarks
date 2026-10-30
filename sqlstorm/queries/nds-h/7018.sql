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
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sales.total_sales
    FROM 
        SupplierSales sales
    JOIN 
        supplier s ON sales.s_suppkey = s.s_suppkey
    WHERE 
        sales.total_sales = (SELECT MAX(total_sales) FROM SupplierSales)
)
SELECT 
    t.s_suppkey,
    t.s_name,
    n.n_name AS nation_name,
    t.total_sales,
    r.r_name AS region_name
FROM 
    TopSuppliers t
JOIN 
    nation n ON t.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    t.total_sales DESC;
