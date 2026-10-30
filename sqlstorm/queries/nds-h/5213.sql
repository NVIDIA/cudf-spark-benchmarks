WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CombinedSummary AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        cs.total_order_value,
        cs.total_orders
    FROM 
        CustomerOrderSummary cs
    JOIN 
        SupplierSummary ss ON cs.total_order_value > ss.total_supply_cost
)
SELECT 
    c.c_name,
    s.s_name,
    SUM(cl.l_extendedprice) AS total_revenue,
    AVG(cl.l_discount) AS avg_discount,
    COUNT(DISTINCT cl.l_orderkey) AS total_orders
FROM 
    CombinedSummary cs
JOIN 
    lineitem cl ON cs.total_order_value > cl.l_extendedprice
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
JOIN 
    supplier s ON cs.s_suppkey = s.s_suppkey
WHERE 
    cl.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, s.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;