WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent,
        co.order_count
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    ORDER BY 
        co.total_spent DESC
    LIMIT 10
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    tc.c_name AS top_customer,
    tc.total_spent,
    sp.total_available,
    sp.total_supply_value
FROM 
    TopCustomers tc
JOIN 
    SupplierParts sp ON sp.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierParts)
ORDER BY 
    tc.total_spent DESC, sp.total_supply_value DESC;