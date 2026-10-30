
WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_details,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        UPPER(SUBSTRING(p.p_name, 1, 5)) AS name_upper,
        LOWER(p.p_comment) AS comment_lower,
        LENGTH(p.p_name) AS name_length,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
)
SELECT 
    sp.p_partkey,
    sp.part_details,
    sp.short_comment,
    sp.name_upper,
    sp.comment_lower,
    sp.name_length,
    sp.comment_length,
    COUNT(s.s_suppkey) AS supplier_count
FROM 
    StringProcessing sp
JOIN 
    partsupp ps ON sp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    sp.p_partkey, sp.part_details, sp.short_comment, sp.name_upper, sp.comment_lower, sp.name_length, sp.comment_length
ORDER BY 
    sp.name_length DESC, supplier_count DESC;
