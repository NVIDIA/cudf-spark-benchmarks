WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l 
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey 
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey 
    GROUP BY 
        n.n_name
),
SupplierPartSales AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_sales
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    GROUP BY 
        s.s_name 
),
TopSuppliers AS (
    SELECT 
        supplier_name,
        supplier_sales,
        RANK() OVER (ORDER BY supplier_sales DESC) AS supplier_rank
    FROM 
        SupplierPartSales
)
SELECT 
    rs.nation_name,
    rs.total_sales,
    ts.supplier_name,
    ts.supplier_sales
FROM 
    RegionalSales rs 
LEFT OUTER JOIN 
    TopSuppliers ts ON rs.nation_name LIKE '%' || SUBSTRING(ts.supplier_name FROM 1 FOR 4) || '%'
WHERE 
    (rs.total_sales > 10000 OR ts.supplier_sales IS NULL) 
    AND ts.supplier_rank < 6
ORDER BY 
    rs.total_sales DESC, 
    ts.supplier_sales DESC;
