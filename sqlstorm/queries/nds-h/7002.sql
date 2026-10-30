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
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
    ORDER BY 
        total_spent DESC 
    LIMIT 10
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_available,
        sp.total_supply_cost
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.total_supply_cost < (SELECT AVG(total_supply_cost) FROM SupplierParts)
    ORDER BY 
        total_supply_cost ASC 
    LIMIT 5
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    ts.s_suppkey,
    ts.s_name,
    tc.order_count,
    tc.total_spent,
    ts.total_available,
    ts.total_supply_cost
FROM 
    TopCustomers tc
CROSS JOIN 
    TopSuppliers ts
WHERE 
    tc.order_count > 2 AND ts.total_available > 100
ORDER BY 
    tc.total_spent DESC, ts.total_supply_cost ASC;
