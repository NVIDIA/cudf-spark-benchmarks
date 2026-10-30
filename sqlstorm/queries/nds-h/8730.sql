WITH SupplierCost AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        sc.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey, 
        co.c_name,
        co.order_count,
        co.total_spent
    FROM 
        CustomerOrders co
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    ts.s_suppkey,
    ts.s_name AS supplier_name,
    tc.c_custkey,
    tc.c_name AS customer_name,
    tc.order_count,
    tc.total_spent
FROM 
    TopSuppliers ts
CROSS JOIN 
    TopCustomers tc
WHERE 
    tc.total_spent > 1000; 
