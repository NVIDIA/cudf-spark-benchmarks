WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        LENGTH(p.p_name) AS name_length, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY LENGTH(p.p_name) ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.name_length, 
        rp.total_supply_cost, 
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5 AND 
        UPPER(rp.p_name) LIKE 'A%' 
)
SELECT 
    fp.p_partkey, 
    fp.p_name,
    fp.name_length,
    fp.total_supply_cost,
    fp.supplier_count,
    CONCAT('Part: ', fp.p_name, ' | Suppliers: ', fp.supplier_count) AS summary
FROM 
    FilteredParts fp
ORDER BY 
    fp.total_supply_cost DESC;
