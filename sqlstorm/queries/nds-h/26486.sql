WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rn
    FROM 
        RankedSuppliers
)
SELECT 
    fs.s_name,
    fs.nation_name,
    fs.part_count,
    fs.total_supply_cost
FROM 
    FilteredSuppliers fs
WHERE 
    fs.rn <= 5
ORDER BY 
    fs.nation_name, fs.total_supply_cost DESC;
