
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales
    FROM 
        SupplierSales ss
    WHERE 
        ss.sales_rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    t.s_name,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(co.total_spent, 0) > 10000 THEN 'High Value'
        WHEN COALESCE(co.total_spent, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    TopSuppliers t
LEFT JOIN 
    CustomerOrders co ON t.s_suppkey = co.c_custkey
ORDER BY 
    t.total_sales DESC, total_orders DESC;
