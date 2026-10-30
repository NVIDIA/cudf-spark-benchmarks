WITH  string_benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        p.p_comment,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        'Part Name: ' || p.p_name || ' | Comment: ' || p.p_comment AS concatenated_string
    FROM 
        part p
    WHERE 
        p.p_size > 0

    UNION ALL

    SELECT 
        ps.ps_partkey,
        s.s_name AS p_name,
        s.s_comment AS p_comment,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_comment) AS comment_length,
        'Supplier Name: ' || s.s_name || ' | Comment: ' || s.s_comment AS concatenated_string
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    WHERE 
        ps.ps_availqty > 0
)

SELECT 
    p.p_partkey,
    AVG(name_length) AS avg_name_length,
    AVG(comment_length) AS avg_comment_length,
    COUNT(*) AS total_records,
    STRING_AGG(concatenated_string, '; ') AS aggregated_strings
FROM 
    string_benchmark p
GROUP BY 
    p.p_partkey
ORDER BY 
    total_records DESC
LIMIT 10;
