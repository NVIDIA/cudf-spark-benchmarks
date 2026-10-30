
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rnk
    FROM 
        customer c
),
HighValueSuppliers AS (
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
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CombinedData AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_mktsegment,
        s.s_name AS supplier_name,
        li.l_quantity,
        li.l_extendedprice
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        c.c_custkey IN (SELECT c_custkey FROM RankedCustomers WHERE rnk <= 10)
        AND s.s_suppkey IN (SELECT s_suppkey FROM HighValueSuppliers)
)
SELECT 
    m.c_mktsegment, 
    AVG(c.o_totalprice) AS average_order_value, 
    COUNT(DISTINCT c.o_orderkey) AS total_orders, 
    SUM(c.l_quantity) AS total_quantity_ordered, 
    SUM(c.l_extendedprice) AS total_revenue 
FROM 
    CombinedData c
JOIN 
    customer m ON c.customer_name = m.c_name 
GROUP BY 
    m.c_mktsegment 
ORDER BY 
    total_revenue DESC;
