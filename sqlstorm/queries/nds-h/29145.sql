WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighVolumeSuppliers AS (
    SELECT 
        r.r_name AS region,
        ns.n_name AS nation,
        rs.s_name AS supplier_name,
        rs.part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn <= 10
)
SELECT 
    region, 
    nation,
    supplier_name,
    part_count,
    LEFT(supplier_name, 10) AS short_name,
    REPLACE(supplier_name, ' ' , '_') AS underscore_name,
    CONCAT(region, '-', nation) AS region_nation,
    CONCAT('Supplier ', supplier_name, ' operates in ', region, ' region and ', nation, ' nation with ', part_count, ' parts supplied.') AS supplier_summary
FROM 
    HighVolumeSuppliers
ORDER BY 
    region, nation, part_count DESC;
