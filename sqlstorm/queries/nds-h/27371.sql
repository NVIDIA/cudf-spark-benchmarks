WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type,
        LOWER(REPLACE(p.p_comment, 'a', '@')) AS modified_comment,
        SUBSTRING(p.p_name, 1, 10) AS name_substr,
        LENGTH(p.p_comment) AS comment_length,
        TRIM(p.p_comment) AS trimmed_comment
    FROM part p
    WHERE p.p_size > 10
),
Aggregated AS (
    SELECT 
        sp.brand_type,
        COUNT(sp.p_partkey) AS part_count,
        AVG(sp.comment_length) AS avg_comment_length,
        MAX(sp.modified_comment) AS max_modified_comment
    FROM StringProcessing sp
    GROUP BY sp.brand_type
)
SELECT 
    a.brand_type,
    a.part_count,
    a.avg_comment_length,
    REPLACE(a.max_modified_comment, '@', 'a') AS original_comment
FROM Aggregated a
WHERE a.part_count > 5
ORDER BY a.avg_comment_length DESC
LIMIT 10;
