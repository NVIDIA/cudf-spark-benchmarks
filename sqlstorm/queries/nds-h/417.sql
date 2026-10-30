
WITH supplier_totals AS (
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
customer_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS nation_name,
    nr.region_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    COALESCE(SUM(st.total_supply_cost), 0) AS total_supply_cost,
    AVG(cs.total_spent) AS avg_spent,
    RANK() OVER (PARTITION BY ns.n_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spent
FROM 
    customer_summary cs
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
JOIN 
    nation_region nr ON c.c_nationkey = nr.n_nationkey
LEFT JOIN 
    supplier_totals st ON c.c_nationkey = st.s_suppkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation ns ON c.c_nationkey = ns.n_nationkey
GROUP BY 
    ns.n_nationkey, ns.n_name, nr.region_name
HAVING 
    COUNT(DISTINCT cs.c_custkey) > 1
ORDER BY 
    total_supply_cost DESC, avg_spent ASC;
