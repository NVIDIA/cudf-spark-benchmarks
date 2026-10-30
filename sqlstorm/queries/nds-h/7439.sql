WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
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
        stats.total_available_qty,
        stats.avg_supply_cost,
        stats.total_parts_supplied,
        RANK() OVER (ORDER BY stats.total_available_qty DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        SupplierStats stats ON s.s_suppkey = stats.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    ts.s_name AS supplier_name,
    ts.total_available_qty,
    ts.avg_supply_cost,
    tc.c_name AS customer_name,
    tc.total_orders,
    tc.total_spent
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON tc.customer_rank <= 10
WHERE 
    ts.supplier_rank <= 10
ORDER BY 
    ts.total_available_qty DESC, tc.total_spent DESC;
