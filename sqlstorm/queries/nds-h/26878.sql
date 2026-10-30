
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_regionkey, r.r_name
)
SELECT 
    rs.s_suppkey, 
    rs.s_name, 
    rs.region_name, 
    rs.part_count,
    rs.total_supply_cost,
    CONCAT('Supplier ', rs.s_name, ' in region ', rs.region_name, 
           ' supplies ', rs.part_count, ' parts totaling $', 
           CAST(rs.total_supply_cost AS STRING) || '.' ) AS summary
FROM 
    RankedSuppliers rs
WHERE 
    rs.rn = 1
ORDER BY 
    rs.total_supply_cost DESC;
