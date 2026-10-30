WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_supply_cost,
        sp.part_count,
        ROW_NUMBER() OVER (ORDER BY sp.total_supply_cost DESC) AS rn
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.part_count > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    t.s_name AS supplier_name,
    t.total_supply_cost,
    t.part_count,
    co.c_name AS customer_name,
    co.total_spent
FROM 
    TopSuppliers t
JOIN 
    CustomerOrders co ON t.rn = co.c_custkey % 10
WHERE 
    t.total_supply_cost > 1000000
ORDER BY 
    t.total_supply_cost DESC, co.total_spent DESC;