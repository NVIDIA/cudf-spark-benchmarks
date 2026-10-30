WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_nationkey
),
FilteredRegions AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    fs.s_name,
    fs.total_parts,
    fs.total_supply_cost
FROM RankedSuppliers fs
JOIN FilteredRegions r ON fs.s_nationkey = r.nation_count
WHERE fs.rank_cost <= 3 AND fs.rank_parts <= 3
ORDER BY r.r_name, fs.total_supply_cost DESC;
