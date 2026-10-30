
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 10
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
),
TopCustomers AS (
    SELECT 
        cot.c_custkey,
        cot.c_name,
        cot.total_order_value,
        RANK() OVER (ORDER BY cot.total_order_value DESC) AS customer_rank
    FROM 
        CustomerOrderTotals cot
    WHERE 
        cot.total_order_value > 0
)
SELECT 
    tc.c_name AS top_customer,
    ts.s_name AS top_supplier,
    ts.total_supply_cost,
    tc.total_order_value
FROM 
    TopCustomers tc
JOIN 
    TopSuppliers ts ON tc.total_order_value > 10000
ORDER BY 
    tc.total_order_value DESC, 
    ts.total_supply_cost DESC
LIMIT 5;
