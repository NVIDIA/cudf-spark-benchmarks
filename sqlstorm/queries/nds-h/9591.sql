WITH CustomerOrders AS (
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
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.*,
        co.order_count,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
TopSuppliers AS (
    SELECT 
        s.*,
        sp.total_available,
        sp.total_cost
    FROM 
        supplier s
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.s_suppkey
    WHERE 
        sp.total_available > (SELECT AVG(total_available) FROM SupplierParts)
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_spent AS customer_spending,
    ts.s_name AS supplier_name,
    ts.total_cost AS supplier_cost
FROM 
    TopCustomers tc
CROSS JOIN 
    TopSuppliers ts
WHERE 
    tc.order_count > 5
ORDER BY 
    tc.total_spent DESC, ts.total_cost ASC
LIMIT 100;
