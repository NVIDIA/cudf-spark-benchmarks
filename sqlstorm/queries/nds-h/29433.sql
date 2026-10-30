
WITH String_Processed AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_mfgr) AS processed_name,
        UPPER(p.p_comment) AS upper_comment,
        LENGTH(TRIM(p.p_comment)) AS trimmed_length,
        REPLACE(REPLACE(p.p_comment, ' ', ''), '-', '') AS no_space_comment,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LOWER(p.p_type) AS lower_type
    FROM 
        part p
),
Supplier_Info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS contact_info,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
)
SELECT 
    rp.processed_name,
    rp.upper_comment,
    rp.trimmed_length,
    rp.no_space_comment,
    rp.short_comment,
    rp.lower_type,
    si.contact_info,
    si.comment_length
FROM 
    String_Processed rp
JOIN 
    Supplier_Info si ON MOD(rp.p_partkey, 10) = MOD(si.s_suppkey, 10)
WHERE 
    rp.trimmed_length > 5
ORDER BY 
    rp.lower_type, si.comment_length DESC
LIMIT 50;
