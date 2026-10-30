WITH part_supp_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
nation_region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    prs.p_partkey,
    prs.p_name,
    prs.p_brand,
    prs.total_available_qty,
    prs.total_supply_cost,
    prs.avg_supply_cost,
    cos.c_custkey,
    cos.c_name,
    cos.total_orders,
    cos.total_spent,
    cos.avg_order_value,
    nrs.r_regionkey,
    nrs.r_name,
    nrs.total_nations,
    nrs.total_suppliers
FROM 
    part_supp_summary prs
JOIN 
    customer_order_summary cos ON prs.total_supply_cost > 1000
JOIN 
    nation_region_summary nrs ON nrs.total_nations > 5
WHERE 
    prs.total_available_qty > 500
ORDER BY 
    prs.total_supply_cost DESC, cos.total_spent DESC
LIMIT 50;
