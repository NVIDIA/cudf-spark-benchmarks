WITH StringProcessingBench AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_comment,
        CONCAT('Part: ', p.p_name, ' | Manufacturer: ', p.p_mfgr, ' | Comment: ', p.p_comment) AS detailed_info,
        LENGTH(CONCAT('Part: ', p.p_name, ' | Manufacturer: ', p.p_mfgr, ' | Comment: ', p.p_comment)) AS total_length,
        REPLACE(p.p_comment, 'red', 'blue') AS modified_comment,
        SUBSTRING(p.p_name, 1, 10) AS name_substring,
        UPPER(p.p_brand) AS brand_uppercase,
        LOWER(p.p_type) AS type_lowercase
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    detailed_info,
    total_length,
    modified_comment,
    name_substring,
    brand_uppercase,
    type_lowercase
FROM 
    StringProcessingBench
ORDER BY 
    total_length DESC
LIMIT 100;
