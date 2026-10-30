WITH String_Processing AS (
    SELECT 
        p.p_name,
        CONCAT(SUBSTRING(p.p_name, 1, 5), '...', SUBSTRING(p.p_name, LENGTH(p.p_name) - 4, 5)) AS truncated_name,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        REPLACE(p.p_comment, 'old', 'new') AS updated_comment,
        LENGTH(p.p_comment) AS comment_length,
        (SELECT COUNT(*) FROM lineitem l 
         WHERE l.l_partkey = p.p_partkey) AS lineitem_count
    FROM 
        part p
)
SELECT 
    sp.truncated_name,
    sp.upper_name,
    sp.lower_name,
    sp.updated_comment,
    sp.comment_length,
    sp.lineitem_count
FROM 
    String_Processing sp
WHERE 
    sp.comment_length > 10
ORDER BY 
    sp.lineitem_count DESC, sp.truncated_name ASC;
