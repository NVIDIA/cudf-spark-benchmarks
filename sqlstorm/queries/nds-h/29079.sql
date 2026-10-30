WITH StringBench AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        CONCAT(p.p_name, ' - ', s.s_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name)) AS string_length,
        SUBSTRING(p.p_comment, 1, 10) AS comment_snippet,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9]', '') AS cleaned_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
StringAggregates AS (
    SELECT 
        AVG(string_length) AS avg_string_length,
        MAX(string_length) AS max_string_length,
        COUNT(*) AS total_entries,
        COUNT(DISTINCT cleaned_comment) AS unique_comments
    FROM 
        StringBench
)
SELECT 
    sb.p_partkey,
    sb.p_name,
    sb.supplier_name,
    sb.combined_string,
    sb.string_length,
    sb.comment_snippet,
    sa.avg_string_length,
    sa.max_string_length,
    sa.total_entries,
    sa.unique_comments
FROM 
    StringBench sb
CROSS JOIN 
    StringAggregates sa
ORDER BY 
    sb.string_length DESC 
LIMIT 10;
