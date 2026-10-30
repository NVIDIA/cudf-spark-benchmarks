
WITH order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        COUNT(DISTINCT o.o_custkey) AS distinct_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
combined_summary AS (
    SELECT 
        o.o_orderkey AS orderkey,
        o.total_revenue,
        o.distinct_parts,
        s.total_supply_cost
    FROM 
        order_summary o
    JOIN 
        supplier_summary s ON o.distinct_parts > 5
    WHERE 
        o.total_revenue > 10000
)
SELECT 
    c.c_name,
    r.r_name AS region,
    cs.total_revenue,
    cs.distinct_parts,
    cs.total_supply_cost
FROM 
    combined_summary cs
JOIN 
    customer c ON cs.orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    cs.total_revenue DESC
LIMIT 10;
