WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
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
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.total_parts,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON s.s_suppkey = ss.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON c.c_custkey = co.c_custkey
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_supply_cost,
    tc.total_spent
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.total_parts > 10 AND tc.total_orders > 5
WHERE 
    ts.supplier_rank <= 5 AND tc.customer_rank <= 5
ORDER BY 
    ts.total_supply_cost DESC, tc.total_spent DESC;
