
WITH processed_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        CONCAT(SUBSTRING(p.p_name, 1, 10), '...', SUBSTRING(p.p_name, CHAR_LENGTH(p.p_name) - 9, 10)) AS truncated_name,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT supplier_name) AS distinct_suppliers,
    COUNT(*) AS total_parts,
    MAX(truncated_name) AS max_truncated_name
FROM 
    processed_data
GROUP BY 
    region_name
HAVING 
    AVG(comment_length) > 20
ORDER BY 
    avg_comment_length DESC;
