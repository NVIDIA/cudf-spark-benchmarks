WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        s.s_name AS supplier_name,
        CONCAT(LEFT(p.p_name, 20), '...') AS short_name,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.short_name,
        rp.supplier_name,
        rp.comment_length
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_by_price <= 5 AND 
        rp.comment_length > 15
)
SELECT 
    fp.short_name AS part_name,
    fp.supplier_name,
    rp.comment_length
FROM 
    FilteredParts fp
JOIN 
    RankedParts rp ON fp.p_partkey = rp.p_partkey
ORDER BY 
    fp.supplier_name, fp.short_name;
