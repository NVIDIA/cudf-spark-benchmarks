WITH String_Process AS (
    SELECT 
        p.p_name AS part_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT(p.p_mfgr, ' - ', p.p_brand) AS mfgr_brand,
        REPLACE(p.p_type, ' ', '_') AS type_replaced,
        LENGTH(p.p_name) AS name_length,
        CASE 
            WHEN POSITION('special' IN p.p_comment) > 0 THEN 'Contains Special'
            ELSE 'No Special'
        END AS special_indicator
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
    ORDER BY 
        name_length DESC
)
SELECT 
    sp.part_name,
    sp.short_comment,
    sp.mfgr_brand,
    sp.type_replaced,
    sp.special_indicator
FROM 
    String_Process sp
WHERE 
    LENGTH(sp.part_name) > 10 AND 
    sp.special_indicator = 'Contains Special'
LIMIT 20;
