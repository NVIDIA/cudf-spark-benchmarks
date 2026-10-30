WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        LENGTH(p.p_name) AS name_length,
        COUNT(ps.ps_partkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name,
        rp.short_name,
        rp.name_length,
        rp.supplier_count,
        ROW_NUMBER() OVER (PARTITION BY rp.name_length ORDER BY rp.supplier_count DESC) AS rn
    FROM 
        RankedParts rp
    WHERE 
        rp.name_length > 20
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.short_name,
    fp.supplier_count,
    CASE WHEN fp.supplier_count > 5 THEN 'Highly Available' ELSE 'Limited Supply' END AS availability_status
FROM 
    FilteredParts fp
WHERE 
    fp.rn <= 5
ORDER BY 
    fp.supplier_count DESC;
