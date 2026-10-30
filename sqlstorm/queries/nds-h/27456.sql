
WITH supplier_summary AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
customer_orders AS (
    SELECT 
        c.c_name,
        c.c_nationkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, c.c_nationkey
),
region_details AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    rd.r_name,
    ss.s_name,
    ss.total_available_quantity,
    ss.total_supply_cost,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    rd.nation_count
FROM 
    supplier_summary ss
JOIN 
    customer_orders cs ON ss.s_nationkey = cs.c_nationkey
JOIN 
    region_details rd ON cs.c_nationkey = rd.nation_count
ORDER BY 
    rd.nation_count DESC, ss.total_supply_cost DESC;
