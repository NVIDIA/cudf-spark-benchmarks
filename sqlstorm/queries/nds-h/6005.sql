WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationCosts AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(rs.total_supply_cost) AS nation_total_cost
    FROM 
        nation n
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    nc.nation_total_cost,
    CASE 
        WHEN nc.nation_total_cost > (SELECT AVG(nation_total_cost) FROM NationCosts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS cost_comparison
FROM 
    NationCosts nc
JOIN 
    nation n ON nc.n_nationkey = n.n_nationkey
WHERE 
    nc.nation_total_cost > 10000
ORDER BY 
    nc.nation_total_cost DESC;
