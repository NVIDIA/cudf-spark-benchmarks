WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost, 
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
OrderDetails AS (
    SELECT 
        co.c_custkey, 
        SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost
    FROM 
        CustomerOrders co
    JOIN 
        SupplierParts sp ON co.o_orderkey = sp.s_suppkey  
    GROUP BY 
        co.c_custkey
)
SELECT 
    co.c_custkey, 
    co.c_name, 
    COUNT(o.o_orderkey) AS number_of_orders, 
    COALESCE(SUM(od.total_supply_cost), 0) AS total_supply_cost, 
    COALESCE(SUM(co.total_order_value), 0) AS total_order_value
FROM 
    CustomerOrders co
LEFT JOIN 
    OrderDetails od ON co.c_custkey = od.c_custkey
LEFT JOIN 
    orders o ON co.o_orderkey = o.o_orderkey
WHERE 
    co.o_orderdate >= '1996-01-01' AND co.o_orderdate < '1997-01-01'
GROUP BY 
    co.c_custkey, co.c_name
ORDER BY 
    total_order_value DESC
LIMIT 10;