WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
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
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
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
        total_supply_value,
        unique_parts_supplied,
        RANK() OVER (ORDER BY total_supply_value DESC) AS supply_rank
    FROM 
        SupplierStats s
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_orders,
        total_order_value,
        RANK() OVER (ORDER BY total_order_value DESC) AS order_rank
    FROM 
        CustomerOrders c
)
SELECT 
    ts.s_name AS Supplier_Name,
    tc.c_name AS Customer_Name,
    ts.total_supply_value,
    tc.total_order_value,
    tc.total_orders,
    ts.unique_parts_supplied
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.unique_parts_supplied > 5 AND tc.total_orders > 10
WHERE 
    ts.supply_rank <= 10 AND tc.order_rank <= 10
ORDER BY 
    ts.total_supply_value DESC, tc.total_order_value DESC;
