
WITH String_Bench AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUBSTRING(p.p_comment FROM 1 FOR 15) AS short_comment,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS extended_description,
        REPLACE(p.p_name, ' ', '_') AS name_with_underscores,
        CHAR_LENGTH(p.p_name) AS name_length,
        LOWER(p.p_brand) AS brand_lowercase
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 10
)
SELECT 
    sb.p_partkey,
    sb.short_comment,
    sb.extended_description,
    sb.name_with_underscores,
    sb.name_length,
    sb.brand_lowercase,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    String_Bench sb
LEFT JOIN 
    partsupp ps ON sb.p_partkey = ps.ps_partkey
GROUP BY 
    sb.p_partkey, sb.short_comment, sb.extended_description, sb.name_with_underscores, sb.name_length, sb.brand_lowercase
ORDER BY 
    sb.name_length DESC, supplier_count ASC
LIMIT 100;
