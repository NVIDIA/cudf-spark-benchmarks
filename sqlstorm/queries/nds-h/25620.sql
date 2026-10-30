
WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(SUBSTRING(p.p_name, 1, 10), '...', SUBSTRING(p.p_name, CHAR_LENGTH(p.p_name) - 4, 5)) AS truncated_name,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        REPLACE(REPLACE(p.p_comment, 'a', 'X'), 'e', 'Y') AS modified_comment
    FROM 
        part p
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        CHAR_LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
), 
CombinedData AS (
    SELECT 
        sp.p_partkey,
        sp.truncated_name,
        sp.comment_length,
        sp.modified_comment,
        sd.s_name,
        sd.s_address,
        sd.s_phone,
        sd.supplier_comment_length
    FROM 
        StringProcessing sp
    JOIN 
        partsupp ps ON sp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    p_partkey AS partkey,
    truncated_name,
    comment_length,
    modified_comment,
    s_name,
    s_address,
    s_phone,
    supplier_comment_length
FROM 
    CombinedData
WHERE 
    comment_length > 0
ORDER BY 
    supplier_comment_length DESC, 
    comment_length DESC;
