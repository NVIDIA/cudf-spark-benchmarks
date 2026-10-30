WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
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
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (ORDER BY total_supply_value DESC) AS supplier_rank
    FROM 
        RankedSuppliers s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
) 
SELECT 
    c.c_custkey, 
    c.order_count, 
    c.total_spent, 
    t.s_suppkey, 
    t.s_name
FROM 
    CustomerOrders c
JOIN 
    TopSuppliers t ON c.order_count >= 5 
WHERE 
    c.total_spent > 1000.00
ORDER BY 
    c.total_spent DESC, t.s_name ASC
LIMIT 10;
