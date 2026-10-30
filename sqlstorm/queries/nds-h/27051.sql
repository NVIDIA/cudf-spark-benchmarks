WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        TRIM(p.p_mfgr) AS trimmed_mfgr,
        REPLACE(p.p_name, ' ', '_') AS name_with_underscores
    FROM 
        part p
), AggregatedResults AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(name_length) AS avg_name_length,
        AVG(comment_length) AS avg_comment_length
    FROM 
        StringProcessing
)
SELECT 
    sr.r_name, 
    sr.r_comment, 
    ar.total_parts, 
    ar.avg_name_length, 
    ar.avg_comment_length
FROM 
    region sr
CROSS JOIN 
    AggregatedResults ar
WHERE 
    EXISTS (
        SELECT 1 
        FROM nation n 
        WHERE n.n_regionkey = sr.r_regionkey AND n.n_comment LIKE '%important%'
    )
ORDER BY 
    ar.avg_name_length DESC;
