WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        s.s_name,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)

SELECT 
    ts.s_name,
    ts.total_sales,
    ts.total_orders,
    ts.sales_rank
FROM 
    TopSuppliers ts
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;