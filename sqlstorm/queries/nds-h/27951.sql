WITH StringProcessing AS (
    SELECT 
        s.s_name AS supplier_name,
        CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
        LTRIM(RTRIM(s.s_comment)) AS trimmed_comment,
        LENGTH(s.s_comment) AS comment_length,
        REPLACE(s.s_comment, 'good', 'excellent') AS updated_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s_name LIKE 'A%' 
        AND LENGTH(s.s_comment) > 20
)
SELECT 
    supplier_name,
    supplier_info,
    trimmed_comment,
    comment_length,
    updated_comment
FROM 
    StringProcessing
ORDER BY 
    comment_length DESC
LIMIT 10;
