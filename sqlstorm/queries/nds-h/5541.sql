
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost, 
        ps.ps_availqty, 
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        SUM(sp.ps_supplycost * sp.ps_availqty) AS total_value
    FROM 
        SupplierParts sp
    WHERE 
        sp.rn = 1
    GROUP BY 
        sp.s_suppkey, sp.s_name
    HAVING 
        SUM(sp.ps_supplycost * sp.ps_availqty) > 100000
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), OrderValue AS (
    SELECT 
        co.c_custkey, 
        co.c_name, 
        SUM(co.revenue) AS total_revenue
    FROM 
        CustomerOrders co
    GROUP BY 
        co.c_custkey, co.c_name
    HAVING 
        SUM(co.revenue) > 50000
)
SELECT 
    o.c_name AS customer_name, 
    o.total_revenue, 
    COUNT(DISTINCT sp.s_suppkey) AS number_of_suppliers
FROM 
    OrderValue o
JOIN 
    HighValueSuppliers sp ON o.c_custkey = sp.s_suppkey
GROUP BY 
    o.c_name, o.total_revenue
ORDER BY 
    o.total_revenue DESC
LIMIT 10;
