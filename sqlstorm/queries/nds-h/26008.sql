WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Part Name: ', p.p_name, ' | Manufacturer: ', p.p_mfgr, 
               ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS detailed_info,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_mfgr) AS upper_mfgr,
        LOWER(p.p_brand) AS lower_brand,
        REPLACE(p.p_comment, 'old', 'new') AS updated_comment
    FROM 
        part p
    WHERE 
        p.p_size > 10
)
SELECT 
    sp.p_partkey,
    sp.detailed_info,
    sp.name_length,
    sp.upper_mfgr,
    sp.lower_brand,
    sp.updated_comment,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(l.l_discount) AS max_discount
FROM 
    StringProcessing sp
JOIN 
    partsupp ps ON sp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    sp.p_partkey, sp.detailed_info, sp.name_length, sp.upper_mfgr, sp.lower_brand, sp.updated_comment
ORDER BY 
    sp.name_length DESC, supplier_count DESC;
