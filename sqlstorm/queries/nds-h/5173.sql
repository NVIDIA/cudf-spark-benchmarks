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
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
LineItemDetails AS (
    SELECT 
        lo.l_orderkey, 
        lo.l_partkey, 
        lo.l_quantity, 
        lo.l_extendedprice
    FROM 
        lineitem lo
    JOIN 
        CustomerOrders co ON lo.l_orderkey = co.o_orderkey
)
SELECT 
    ts.s_name, 
    COUNT(DISTINCT co.c_custkey) AS total_customers, 
    SUM(lid.l_extendedprice) AS total_revenue
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    LineItemDetails lid ON ps.ps_partkey = lid.l_partkey
JOIN 
    CustomerOrders co ON lid.l_orderkey = co.o_orderkey
GROUP BY 
    ts.s_name 
ORDER BY 
    total_revenue DESC;