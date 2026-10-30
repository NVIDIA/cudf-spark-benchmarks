
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SupplierSales s
)
SELECT 
    c.c_name AS customer_name, 
    c.order_count, 
    COALESCE(c.total_spent, 0) AS total_spent, 
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier
FROM 
    CustomerOrders c
LEFT JOIN 
    TopSuppliers ts ON c.c_custkey = ts.s_suppkey
WHERE 
    c.order_count > (SELECT AVG(order_count) FROM CustomerOrders)
ORDER BY 
    total_spent DESC
LIMIT 10;
