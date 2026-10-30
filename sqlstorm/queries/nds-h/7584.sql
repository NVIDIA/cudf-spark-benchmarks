WITH SupplierStats AS (
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
OrderStats AS (
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
        s.total_available_qty,
        s.total_supply_cost,
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS rank_supplier
    FROM 
        SupplierStats s
),
TopCustomers AS (
    SELECT 
        o.c_custkey,
        o.c_name,
        o.total_orders,
        o.total_order_value,
        RANK() OVER (ORDER BY o.total_order_value DESC) AS rank_customer
    FROM 
        OrderStats o
)
SELECT 
    ts.s_suppkey,
    ts.s_name AS supplier_name,
    tc.c_custkey,
    tc.c_name AS customer_name,
    ts.total_available_qty,
    ts.total_supply_cost,
    tc.total_orders,
    tc.total_order_value
FROM 
    TopSuppliers ts
JOIN 
    TopCustomers tc ON ts.rank_supplier <= 10 AND tc.rank_customer <= 10
ORDER BY 
    ts.total_supply_cost DESC, tc.total_order_value DESC;
