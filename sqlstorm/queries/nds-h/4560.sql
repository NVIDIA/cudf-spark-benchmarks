
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_sales > 0
)
SELECT 
    n.n_name AS nation_name,
    SUM(ss.total_sales) AS nation_sales,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSales ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = s.s_suppkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    SUM(ss.total_sales) > (
        SELECT 
            AVG(total_sales) FROM SupplierSales
    ) OR SUM(ss.total_sales) IS NULL
ORDER BY 
    nation_sales DESC;
