WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        s.s_name
    FROM 
        RankedSuppliers s
    WHERE 
        s.total_supply_cost = (SELECT MAX(total_supply_cost) FROM RankedSuppliers)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
FilteredOrders AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        co.o_orderkey, 
        co.o_orderdate, 
        co.total_amount
    FROM 
        CustomerOrders co
    JOIN 
        TopSuppliers ts ON co.total_amount > (SELECT AVG(total_amount) FROM CustomerOrders)
)
SELECT 
    fo.c_name, 
    COUNT(fo.o_orderkey) AS total_orders, 
    SUM(fo.total_amount) AS total_spent
FROM 
    FilteredOrders fo
GROUP BY 
    fo.c_name
ORDER BY 
    total_spent DESC
LIMIT 10;
