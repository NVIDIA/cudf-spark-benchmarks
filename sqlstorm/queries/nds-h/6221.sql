WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderMetrics AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    AVG(ss.total_supply_cost) AS avg_supply_cost,
    SUM(om.order_value) AS total_order_value,
    SUM(om.total_orders) AS total_orders_per_customer
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    OrderMetrics om ON n.n_nationkey = om.c_custkey
GROUP BY 
    r.r_name
ORDER BY 
    total_orders_per_customer DESC, avg_supply_cost DESC
LIMIT 10;
