WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
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
        total_available_qty,
        total_supply_cost,
        RANK() OVER (ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierParts s
    WHERE 
        total_available_qty > 0
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_orders,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
    WHERE 
        total_orders > 0
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    tc.c_custkey,
    tc.c_name,
    ts.total_available_qty,
    ts.total_supply_cost,
    tc.total_orders,
    tc.total_spent
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.s_suppkey IS NOT NULL AND tc.c_custkey IS NOT NULL
WHERE 
    ts.supplier_rank <= 10 AND tc.customer_rank <= 10
ORDER BY 
    ts.total_supply_cost DESC, tc.total_spent DESC
LIMIT 100;
