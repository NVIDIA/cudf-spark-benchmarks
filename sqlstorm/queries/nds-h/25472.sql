WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        CONCAT(p.p_name, ' ', s.s_name) AS combined_string,
        LENGTH(CONCAT(p.p_name, ' ', s.s_name)) AS combined_length,
        UPPER(p.p_name) AS upper_case_name,
        LOWER(s.s_name) AS lower_case_supplier,
        REPLACE(p.p_comment, 'quality', 'superior') AS modified_comment,
        SUBSTRING(p.p_name, 1, 5) AS name_prefix,
        TRIM(CONCAT(p.p_name, ' ', s.s_name)) AS trimmed_combined,
        LENGTH(TRIM(CONCAT(p.p_name, ' ', s.s_name))) AS trimmed_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    AVG(combined_length) AS avg_string_length,
    MAX(combined_length) AS max_string_length,
    MIN(combined_length) AS min_string_length,
    COUNT(DISTINCT upper_case_name) AS unique_upper_names,
    COUNT(DISTINCT lower_case_supplier) AS unique_lower_suppliers,
    COUNT(DISTINCT name_prefix) AS unique_name_prefixes,
    COUNT(DISTINCT modified_comment) AS unique_comments,
    COUNT(*) AS total_records
FROM 
    StringProcessing
WHERE 
    combined_length > 30;
