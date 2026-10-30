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
        orders o ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) as sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    ns.n_name AS nation_name,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM 
    nation ns
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT MIN(s.s_suppkey) 
                                        FROM TopSuppliers s 
                                        WHERE s.sales_rank = 1)
LEFT JOIN 
    SupplierSales ss ON ss.s_suppkey = ts.s_suppkey
WHERE 
    ns.n_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
ORDER BY 
    ns.n_name, total_sales DESC;
