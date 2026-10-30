
WITH  CTE_Supplier_Rank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
Max_Total_Supply_Cost AS (
    SELECT 
        s_nationkey,
        MAX(total_supply_cost) AS max_supply_cost
    FROM 
        CTE_Supplier_Rank
    GROUP BY 
        s_nationkey
)
SELECT 
    n.n_name,
    s.s_name, 
    s.total_supply_cost,
    CASE 
        WHEN s.total_supply_cost > m.max_supply_cost THEN 'Above Max'
        ELSE 'Below Max'
    END AS cost_comparison,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    CTE_Supplier_Rank s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    Max_Total_Supply_Cost m ON n.n_nationkey = m.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
WHERE 
    s.rank = 1
GROUP BY 
    n.n_name, s.s_name, s.total_supply_cost, m.max_supply_cost
ORDER BY 
    n.n_name, s.total_supply_cost DESC;
