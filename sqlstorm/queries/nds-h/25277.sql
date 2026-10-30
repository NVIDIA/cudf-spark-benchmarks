WITH String_Processing AS (
    SELECT 
        CONCAT('SUPPLIER: ', s_name, ', from Nation: ', n_name, ', Comment: ', s_comment) AS supplier_info,
        LENGTH(s_comment) AS comment_length,
        UPPER(s_name) AS upper_case_name,
        LOWER(s_name) AS lower_case_name,
        REPLACE(s_comment, 'bad', 'good') AS modified_comment
    FROM 
        supplier 
    JOIN 
        nation ON s_nationkey = n_nationkey
    WHERE 
        s_comment LIKE '%bad%'
)
SELECT 
    supplier_info,
    comment_length,
    upper_case_name,
    lower_case_name,
    modified_comment
FROM 
    String_Processing
ORDER BY 
    comment_length DESC
LIMIT 10;
