WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS customer_order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500 AND c.c_name NOT LIKE '%test%'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    ts.s_name,
    ts.total_sales,
    fc.c_name,
    fc.customer_order_count
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    FilteredCustomers fc ON ts.sales_rank = fc.customer_order_count
WHERE 
    ts.total_sales IS NOT NULL OR fc.customer_order_count IS NOT NULL
ORDER BY 
    COALESCE(ts.total_sales, 0) DESC, 
    COALESCE(fc.customer_order_count, 0) DESC
LIMIT 100;