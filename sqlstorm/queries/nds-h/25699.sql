
WITH  string_benchmark AS (
    SELECT 
        p_name AS processed_string,
        LENGTH(p_name) AS string_length,
        LOWER(p_name) AS lower_case,
        UPPER(p_name) AS upper_case,
        TRIM(p_comment) AS trimmed_comment,
        CHAR_LENGTH(p_comment) AS comment_length,
        REPLACE(p_comment, ' ', '-') AS replaced_space,
        CONCAT('Product: ', p_name, ' | Manufacturer: ', p_mfgr) AS concatenated_info,
        ROW_NUMBER() OVER (ORDER BY p_partkey) AS rn
    FROM part
), region_summary AS (
    SELECT 
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count,
        STRING_AGG(DISTINCT n.n_name, ', ') AS nations_list
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    sb.processed_string,
    sb.string_length,
    sb.lower_case,
    sb.upper_case,
    sb.trimmed_comment,
    sb.comment_length,
    sb.replaced_space,
    sb.concatenated_info,
    rs.r_name AS region_name,
    rs.nation_count,
    rs.nations_list
FROM string_benchmark sb
CROSS JOIN region_summary rs
WHERE sb.string_length > 10 AND rs.nation_count > 2
ORDER BY sb.string_length DESC, rs.r_name;
