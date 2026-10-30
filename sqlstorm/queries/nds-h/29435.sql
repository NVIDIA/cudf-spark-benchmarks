
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS nation_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.nation_name,
        r.part_count,
        r.total_supply_cost
    FROM 
        RankedSuppliers r
    WHERE 
        r.nation_rank = 1
)
SELECT 
    p.p_name,
    ts.s_name,
    ts.nation_name,
    ts.total_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    p.p_name LIKE '%Widget%'
ORDER BY 
    ts.total_supply_cost DESC;
