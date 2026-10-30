
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name, r.r_regionkey
), FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.region_name,
        rs.total_parts,
        rs.total_supplycost,
        CASE 
            WHEN rs.total_supplycost > 10000 THEN 'High Supply Cost' 
            ELSE 'Low Supply Cost' 
        END AS supply_cost_category
    FROM RankedSuppliers rs
    WHERE rs.rn <= 5
)
SELECT 
    fs.s_suppkey,
    fs.s_name,
    fs.region_name,
    fs.total_parts,
    fs.total_supplycost,
    fs.supply_cost_category,
    CONCAT('Supplier ', fs.s_name, ' from ', fs.region_name, ' provides ', fs.total_parts, ' parts with a total supply cost of $', CAST(fs.total_supplycost AS VARCHAR(20))) AS summary_message
FROM FilteredSuppliers fs
ORDER BY fs.region_name, fs.total_parts DESC;
