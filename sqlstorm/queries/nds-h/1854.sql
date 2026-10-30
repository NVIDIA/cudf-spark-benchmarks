WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.total_orders
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        s.s_acctbal > 500
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    ts.s_acctbal, 
    ts.total_sales, 
    ts.total_orders,
    CASE 
        WHEN ts.total_sales > 0 THEN ROUND(ts.total_sales / NULLIF(ts.total_orders, 0), 2) 
        ELSE 0 
    END AS avg_order_value
FROM 
    TopSuppliers ts
WHERE 
    ts.total_orders > 5 OR ts.total_sales > 10000
ORDER BY 
    ts.total_sales DESC, 
    ts.s_name;