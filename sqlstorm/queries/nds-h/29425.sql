WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        CONCAT('Part Name: ', p.p_name, ', Supplier: ', s.s_name, ', Nation: ', n.n_name) AS description,
        LENGTH(CONCAT('Part Name: ', p.p_name, ', Supplier: ', s.s_name, ', Nation: ', n.n_name)) AS desc_length,
        REGEXP_REPLACE(LOWER(p.p_comment), '[^a-z]', '') AS sanitized_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    description,
    desc_length,
    COUNT(sanitized_comment) AS valid_comments_count
FROM 
    StringProcessing
WHERE 
    desc_length > 50
GROUP BY 
    description, desc_length
ORDER BY 
    valid_comments_count DESC, desc_length DESC
LIMIT 10;
