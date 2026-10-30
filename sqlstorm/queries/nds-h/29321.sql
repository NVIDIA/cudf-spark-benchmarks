WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_mfgr) AS mfgr_upper,
        SUBSTRING(p.p_comment, 1, 10) AS comment_excerpt,
        REPLACE(p.p_name, ' ', '_') AS name_with_underscores,
        CONCAT('Type: ', p.p_type, ' | Size: ', p.p_size) AS type_size_info,
        LENGTH(REPLACE(p.p_comment, ' ', '')) AS comment_char_count
    FROM 
        part p
),
SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info,
        LENGTH(s.s_comment) AS comment_length,
        POSITION('reliable' IN s.s_comment) AS reliable_position
    FROM 
        supplier s
)
SELECT 
    sm.p_partkey,
    sm.name_length,
    sm.mfgr_upper,
    sm.comment_excerpt,
    sm.name_with_underscores,
    sm.type_size_info,
    sm.comment_char_count,
    su.s_suppkey,
    su.supplier_info,
    su.comment_length,
    su.reliable_position
FROM 
    StringMetrics sm
JOIN 
    SupplierMetrics su ON sm.name_length < su.comment_length
WHERE 
    sm.comment_char_count > 50
ORDER BY 
    sm.name_length DESC, su.comment_length ASC;
