WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
        ss.unique_parts_supplied,
        ss.total_supply_value,
        RANK() OVER (ORDER BY ss.total_supply_value DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
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
        customer c ON co.c_custkey = c.c_custkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name AS supplier_name,
    ts.unique_parts_supplied,
    ts.total_supply_value,
    tc.c_custkey,
    tc.c_name AS customer_name,
    tc.total_orders,
    tc.total_spent
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.supplier_rank <= 5 AND tc.customer_rank <= 5
ORDER BY 
    ts.total_supply_value DESC, tc.total_spent DESC;
