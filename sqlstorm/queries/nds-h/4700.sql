
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_sales
    FROM 
        SupplierSales
),
QualifiedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales,
        ss.order_count,
        CASE 
            WHEN ss.total_sales = ms.max_sales THEN 'Top Supplier'
            ELSE 'Regular Supplier'
        END AS supplier_type
    FROM 
        SupplierSales ss
        CROSS JOIN MaxSales ms
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
        LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    q.s_name,
    q.total_sales,
    q.order_count,
    COALESCE(c.total_orders, 0) AS customer_order_count,
    c.c_name AS associated_customer
FROM 
    QualifiedSuppliers q
LEFT JOIN CustomerOrderCounts c ON q.order_count = c.total_orders
WHERE 
    q.total_sales IS NOT NULL
ORDER BY 
    q.total_sales DESC, 
    q.s_name ASC
LIMIT 10;
