WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_details,
        LENGTH(p.p_comment) AS comment_length,
        UPPER(p.p_name) AS upper_part_name,
        LOWER(p.p_name) AS lower_part_name,
        REPLACE(p.p_comment, 'excellent', 'superb') AS modified_comment,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
        (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) AS usa_supplier_count
    FROM 
        part p
    WHERE 
        p.p_size > 10
)
SELECT 
    sb.part_details,
    sb.comment_length,
    sb.upper_part_name,
    sb.lower_part_name,
    sb.modified_comment,
    sb.short_comment,
    sb.usa_supplier_count
FROM 
    StringBenchmark sb
WHERE 
    sb.comment_length > 5
ORDER BY 
    sb.comment_length DESC
LIMIT 50;
