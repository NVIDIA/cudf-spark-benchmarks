WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_type) AS type_length,
        CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS sup_part_info,
        TRIM(REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9 ]', '')) AS cleaned_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
BenchmarkResults AS (
    SELECT 
        COUNT(*) AS total_parts,
        SUM(LENGTH(upper_name)) AS total_upper_length,
        SUM(LENGTH(lower_comment)) AS total_lower_length,
        SUM(type_length) AS total_type_length,
        COUNT(DISTINCT cleaned_comment) AS unique_cleaned_comments
    FROM 
        StringProcessing
)
SELECT 
    *,
    total_parts * 1.0 / NULLIF(total_upper_length, 0) AS avg_upper_length_per_part,
    total_parts * 1.0 / NULLIF(total_lower_length, 0) AS avg_lower_length_per_part,
    total_parts * 1.0 / NULLIF(unique_cleaned_comments, 0) AS avg_unique_cleaned_comments_per_part
FROM 
    BenchmarkResults;
