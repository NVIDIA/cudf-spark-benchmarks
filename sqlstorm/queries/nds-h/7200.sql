
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 20
    GROUP BY 
        s.s_name, s.s_suppkey, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_name
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    ts.s_name AS top_supplier,
    ts.total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    TopSuppliers ts ON ts.total_supply_cost = (
        SELECT MAX(total_supply_cost) FROM TopSuppliers
    )
ORDER BY 
    co.total_spent DESC
LIMIT 10;
