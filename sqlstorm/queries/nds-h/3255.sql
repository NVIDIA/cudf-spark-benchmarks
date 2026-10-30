WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
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
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.orders_count
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.sales_rank <= 10
)

SELECT 
    ts.s_suppkey,
    ts.s_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.orders_count, 0) AS orders_count,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     JOIN orders o ON c.c_custkey = o.o_custkey 
     WHERE o.o_orderdate >= DATE '1997-01-01' 
     AND o.o_orderstatus = 'F') AS total_customers
FROM 
    TopSuppliers ts
LEFT JOIN 
    region r ON ts.s_suppkey % 5 = r.r_regionkey
WHERE 
    r.r_regionkey IS NULL OR r.r_regionkey > 2
ORDER BY 
    ts.total_sales DESC;