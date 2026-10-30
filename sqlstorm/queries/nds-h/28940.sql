
WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT(p.p_name, ' - ', s.s_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name)) AS combined_length,
        SUBSTR(p.p_comment, 1, 10) AS comment_excerpt,
        UPPER(s.s_comment) AS supplier_comment_uppercase,
        LOWER(p.p_brand) AS converted_brand,
        REPLACE(p.p_comment, 'test', 'TEST') AS comment_replaced,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    part_name,
    supplier_name,
    combined_string,
    combined_length,
    comment_excerpt,
    supplier_comment_uppercase,
    converted_brand,
    comment_replaced,
    comment_length
FROM 
    StringProcessing
WHERE 
    combined_length > 30
ORDER BY 
    combined_length DESC
LIMIT 100;
