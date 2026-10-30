WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    ts.s_name AS top_supplier,
    ts.total_cost,
    rp.total_supply_cost,
    (rp.total_supply_cost - ts.total_cost) AS cost_difference
FROM 
    ranked_parts rp
JOIN 
    top_suppliers ts ON rp.rank = 1
WHERE 
    rp.total_supply_cost > ts.total_cost
ORDER BY 
    rp.total_supply_cost DESC
LIMIT 10;
