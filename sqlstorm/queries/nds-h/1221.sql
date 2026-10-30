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
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_sales,
    t.order_count,
    CASE 
        WHEN t.sales_rank <= 5 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_type,
    r.r_name,
    n.n_name
FROM 
    TopSuppliers t
LEFT JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.total_sales > (
        SELECT AVG(total_sales) 
        FROM SupplierSales
    )
ORDER BY 
    t.total_sales DESC
LIMIT 10;
