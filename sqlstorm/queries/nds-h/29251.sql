WITH StringProcessing AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        CONCAT('Part: ', p.p_name, ' (', p.p_brand, ') supplied by ', s.s_name) AS detailed_info,
        LENGTH(CONCAT('Part: ', p.p_name, ' (', p.p_brand, ') supplied by ', s.s_name)) AS info_length,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal > 5000
)
SELECT 
    part_name, 
    supplier_name, 
    detailed_info, 
    info_length,
    short_comment,
    supplier_count
FROM 
    StringProcessing
ORDER BY 
    info_length DESC
LIMIT 10;
