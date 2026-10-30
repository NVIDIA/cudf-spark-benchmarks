WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        LENGTH(p.p_name) AS name_length,
        COUNT(ps.ps_partkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
FilteredParts AS (
    SELECT 
        rp.*, 
        ROW_NUMBER() OVER (PARTITION BY rp.p_brand ORDER BY rp.total_avail_qty DESC) AS rn
    FROM 
        RankedParts rp
    WHERE 
        rp.name_length > 10 AND 
        rp.total_avail_qty > 100
)
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_brand, 
    fp.p_type, 
    fp.supplier_count
FROM 
    FilteredParts fp
WHERE 
    fp.rn <= 5
ORDER BY 
    fp.p_brand, fp.supplier_count DESC;
