WITH String_Processing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Part: ', p.p_name, ' | Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS part_details,
        REPLACE(p.p_comment, 'old', 'new') AS updated_comment,
        LENGTH(p.p_comment) AS original_comment_length,
        LENGTH(REPLACE(p.p_comment, 'old', 'new')) AS updated_comment_length
    FROM 
        part p
    WHERE 
        p.p_size > 10
)
SELECT 
    sp.p_partkey,
    sp.part_details,
    sp.updated_comment,
    sp.original_comment_length,
    sp.updated_comment_length,
    (sp.original_comment_length - sp.updated_comment_length) AS length_difference
FROM 
    String_Processing sp
WHERE 
    sp.updated_comment_length < sp.original_comment_length
ORDER BY 
    length_difference DESC
LIMIT 10;
