WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' | ', p.p_mfgr, ' | ', p.p_brand) AS part_details,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'abc', 'xyz') AS modified_comment,
        LOWER(SUBSTRING(p.p_name, 1, 10)) AS part_name_substr,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_comment
)
SELECT 
    sp.part_details,
    sp.comment_length,
    sp.modified_comment,
    sp.part_name_substr,
    sp.supplier_count,
    CASE 
        WHEN sp.comment_length > 20 THEN 'Long Comment'
        ELSE 'Short Comment'
    END AS comment_length_category
FROM StringProcessing sp
WHERE sp.supplier_count > 5
ORDER BY sp.comment_length DESC;
