WITH StringProcesses AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS combined_info,
        UPPER(p.p_comment) AS upper_comment,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(s.s_comment, 's', 'X') AS modified_supplier_comment,
        REGEXP_REPLACE(s.s_address, '[^a-zA-Z0-9 ]', '') AS sanitized_address
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    combined_info,
    upper_comment,
    comment_length,
    modified_supplier_comment,
    sanitized_address
FROM 
    StringProcesses
WHERE 
    comment_length > 10
ORDER BY 
    upper_comment ASC, 
    combined_info DESC;
