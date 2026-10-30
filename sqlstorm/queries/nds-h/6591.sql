
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_avail_qty,
        sp.total_supply_value,
        RANK() OVER (ORDER BY sp.total_supply_value DESC) AS rank
    FROM 
        SupplierParts sp
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
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
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        CustomerOrders co
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_avail_qty,
    ts.total_supply_value,
    tc.total_orders,
    tc.total_spent
FROM 
    TopSuppliers ts
JOIN 
    lineitem li ON li.l_suppkey = ts.s_suppkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    TopCustomers tc ON o.o_custkey = tc.c_custkey
WHERE 
    ts.rank <= 10 AND tc.rank <= 10
ORDER BY 
    ts.total_supply_value DESC, tc.total_spent DESC;
