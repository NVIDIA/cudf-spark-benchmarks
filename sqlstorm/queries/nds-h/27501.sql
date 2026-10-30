WITH StringProcessing AS (
    SELECT
        p.p_partkey,
        CONCAT('Part Name: ', p.p_name, ' | Manufactured by: ', p.p_mfgr, ' | Type: ', p.p_type) AS part_info,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        LENGTH(p.p_comment) AS comment_length,
        RANK() OVER (ORDER BY LENGTH(p.p_comment) DESC) AS comment_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
),
AggregatedData AS (
    SELECT
        SUBSTRING(part_info, 1, 40) AS summarized_info,
        AVG(comment_length) AS avg_comment_length,
        COUNT(*) AS total_parts
    FROM StringProcessing
    WHERE comment_rank <= 10
    GROUP BY summarized_info
)
SELECT
    summarized_info,
    avg_comment_length,
    total_parts,
    CONCAT('Total parts with long comments: ', total_parts + 100) AS adjusted_total
FROM AggregatedData
WHERE total_parts > 5
ORDER BY avg_comment_length DESC;
