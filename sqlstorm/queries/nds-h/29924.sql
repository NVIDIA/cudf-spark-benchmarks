WITH string_processing AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_name) AS name_length,
        SUBSTR(p.p_comment, 1, 10) AS comment_excerpt,
        REGEXP_REPLACE(p.p_comment, '^[^ ]+', 'REPLACED') AS replaced_comment,
        CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type,
        TRIM(p.p_comment) AS trimmed_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50
)
SELECT 
    sp.upper_name,
    sp.lower_comment,
    sp.name_length,
    sp.comment_excerpt,
    sp.replaced_comment,
    sp.brand_type,
    sp.trimmed_comment,
    COUNT(*) OVER() AS total_rows
FROM 
    string_processing sp
ORDER BY 
    sp.name_length DESC, 
    sp.upper_name ASC
LIMIT 100;
