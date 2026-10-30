
WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        LOWER(p.p_name) AS lower_name,
        UPPER(p.p_name) AS upper_name,
        REPLACE(p.p_comment, 'small', 'tiny') AS adjusted_comment
    FROM 
        part p
),
AggregatedMetrics AS (
    SELECT 
        AVG(name_length) AS avg_name_length,
        AVG(comment_length) AS avg_comment_length,
        COUNT(DISTINCT lower_name) AS distinct_lower_names,
        COUNT(DISTINCT upper_name) AS distinct_upper_names
    FROM 
        StringMetrics
),
SupplierCommentAnalysis AS (
    SELECT 
        s.s_suppkey,
        CHAR_LENGTH(s.s_comment) - CHAR_LENGTH(REPLACE(s.s_comment, ' ', '')) AS space_count,
        CASE 
            WHEN s.s_comment LIKE '%important%' THEN 1
            ELSE 0 
        END AS has_important_comment
    FROM 
        supplier s
)
SELECT 
    am.avg_name_length,
    am.avg_comment_length,
    am.distinct_lower_names,
    am.distinct_upper_names,
    COUNT(sca.s_suppkey) AS supplier_with_important_comments,
    SUM(sca.space_count) AS total_spaces_in_comments
FROM 
    AggregatedMetrics am
LEFT JOIN 
    SupplierCommentAnalysis sca ON true
GROUP BY 
    am.avg_name_length, am.avg_comment_length, am.distinct_lower_names, am.distinct_upper_names;
