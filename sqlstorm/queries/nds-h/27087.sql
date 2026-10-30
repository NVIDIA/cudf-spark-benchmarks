WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
MaxPartCount AS (
    SELECT 
        MAX(part_count) AS max_count
    FROM 
        RankedSuppliers
)
SELECT 
    r.r_name,
    rs.s_name,
    rs.part_count,
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    region r ON rs.s_nationkey = r.r_regionkey
WHERE 
    rs.part_count = (SELECT max_count FROM MaxPartCount)
ORDER BY 
    r.r_name, rs.s_name;
