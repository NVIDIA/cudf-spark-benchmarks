WITH  string_benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'soft', 'firm') AS modified_comment,
        CONCAT(p.p_name, ' - ', p.p_comment) AS full_description
    FROM 
        part p
    WHERE 
        p.p_size >= 10
    UNION ALL
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        s.s_comment,
        SUBSTRING(s.s_name, 1, 10),
        LENGTH(s.s_comment),
        REPLACE(s.s_comment, 'factory', 'plant'),
        CONCAT(s.s_name, ' - ', s.s_comment)
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
aggregated_results AS (
    SELECT 
        COUNT(*) AS total_records,
        AVG(comment_length) AS avg_comment_length,
        MAX(LENGTH(full_description)) AS max_description_length
    FROM 
        string_benchmark
)
SELECT 
    a.total_records,
    a.avg_comment_length,
    a.max_description_length,
    STRING_AGG(CONCAT(sb.short_name, ': ', sb.modified_comment), '; ') AS sample_modified_comments
FROM 
    aggregated_results a
JOIN 
    string_benchmark sb ON a.total_records > 0
GROUP BY 
    a.total_records, a.avg_comment_length, a.max_description_length
ORDER BY 
    a.total_records DESC;
