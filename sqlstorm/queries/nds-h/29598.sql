
WITH string_benchmark AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name) AS combined_info,
        LENGTH(p.p_comment) AS comment_length,
        LOWER(p.p_comment) AS lower_comment,
        UPPER(s.s_name) AS upper_supplier_name,
        REPLACE(p.p_comment, 'old', 'new') AS modified_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_part_name,
        CHAR_LENGTH(p.p_name) AS part_name_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
final_benchmark AS (
    SELECT
        sb.combined_info,
        sb.comment_length,
        sb.lower_comment,
        sb.upper_supplier_name,
        sb.modified_comment,
        sb.short_part_name,
        sb.part_name_length,
        RANK() OVER (ORDER BY sb.comment_length DESC) AS comment_rank
    FROM 
        string_benchmark sb
)
SELECT 
    *
FROM 
    final_benchmark
WHERE 
    comment_rank <= 10;
