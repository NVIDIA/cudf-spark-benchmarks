WITH StringProcessing AS (
    SELECT 
        p.p_name, 
        s.s_name AS supplier_name, 
        CONCAT(s.s_name, ' supplies ', p.p_name) AS description,
        LENGTH(CONCAT(s.s_name, ' supplies ', p.p_name)) AS description_length,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
        UPPER(p.p_type) AS upper_type
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_name LIKE 'Rubber%'
)
SELECT 
    description, 
    description_length, 
    short_comment, 
    upper_type 
FROM 
    StringProcessing 
WHERE 
    description_length > 50 
ORDER BY 
    description_length DESC;
