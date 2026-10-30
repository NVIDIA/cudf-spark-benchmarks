WITH StringProcessing AS (
    SELECT 
        p.p_name,
        s.s_name,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        LENGTH(p.p_name) AS name_length,
        REPLACE(UPPER(p.p_name), ' ', '_') AS modified_name,
        CONCAT(s.s_name, ' (', p.p_name, ')') AS combined_name_supplier,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    short_comment,
    name_length,
    modified_name,
    combined_name_supplier,
    sanitized_comment
FROM 
    StringProcessing
WHERE 
    name_length > 10
ORDER BY 
    name_length DESC
LIMIT 100;
