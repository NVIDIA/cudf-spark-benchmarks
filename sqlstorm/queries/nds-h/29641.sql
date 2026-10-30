WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTR(p.p_comment, 1, 10) AS short_comment,
        REPLACE(p.p_name, ' ', '-') AS hyphenated_name,
        UPPER(p.p_mfgr) AS upper_mfgr,
        LOWER(p.p_type) AS lower_type,
        CONCAT(p.p_brand, ': ', p.p_type) AS brand_type_combination
    FROM 
        part p
)
SELECT 
    sp.p_partkey,
    sp.name_length,
    sp.short_comment,
    sp.hyphenated_name,
    sp.upper_mfgr,
    sp.lower_type,
    sp.brand_type_combination,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    StringProcessing sp
LEFT JOIN 
    partsupp ps ON sp.p_partkey = ps.ps_partkey
GROUP BY 
    sp.p_partkey, sp.name_length, sp.short_comment, sp.hyphenated_name, 
    sp.upper_mfgr, sp.lower_type, sp.brand_type_combination
ORDER BY 
    sp.name_length DESC, sp.p_partkey;
