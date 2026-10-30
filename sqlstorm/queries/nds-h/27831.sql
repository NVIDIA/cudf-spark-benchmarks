
WITH String_Processing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS mfgr_brand,
        INITCAP(p.p_type) AS formatted_type,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'size', 'dimension') AS modified_comment,
        COUNT(DISTINCT s.s_name) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_comment
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    sp.mfgr_brand,
    sp.formatted_type,
    CASE 
        WHEN sp.comment_length > 15 THEN 'Long Comment' 
        ELSE 'Short Comment' 
    END AS comment_description,
    sp.modified_comment,
    sp.supplier_count
FROM String_Processing sp
WHERE sp.supplier_count > 1
ORDER BY sp.supplier_count DESC, sp.p_name;
