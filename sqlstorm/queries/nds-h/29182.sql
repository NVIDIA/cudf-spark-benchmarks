
WITH String_Analysis AS (
    SELECT 
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        REPLACE(p.p_comment, 'foo', 'bar') AS modified_comment,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS comment_preview,
        CASE 
            WHEN POSITION('excellent' IN p.p_comment) > 0 THEN 'Contains Excellent'
            ELSE 'No Excellent'
        END AS comment_quality
    FROM 
        part p
), Supplier_Analysis AS (
    SELECT 
        s.s_name,
        CHAR_LENGTH(s.s_name) AS supplier_name_length,
        LEFT(s.s_name, 5) AS supplier_name_start,
        RIGHT(s.s_name, 5) AS supplier_name_end,
        CONCAT('Supplier: ', s.s_name) AS full_supplier_name
    FROM 
        supplier s
)
SELECT 
    sa.supplier_name_start,
    sa.supplier_name_end,
    sa.supplier_name_length,
    sa.full_supplier_name,
    strs.name_upper,
    strs.name_length,
    strs.modified_comment,
    strs.comment_preview,
    strs.comment_quality
FROM 
    Supplier_Analysis sa
JOIN 
    String_Analysis strs ON sa.supplier_name_length = strs.name_length
ORDER BY 
    strs.name_length DESC, sa.supplier_name_length DESC
LIMIT 100;
