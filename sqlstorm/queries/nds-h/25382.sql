WITH StringManipulation AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS uppercase_name,
        LOWER(p.p_comment) AS lowercase_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT('Part: ', p.p_name, ' | Comment Length: ', LENGTH(p.p_comment)) AS formatted_comment,
        REPLACE(p.p_comment, 'leverage', 'utilize') AS modified_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info
    FROM 
        supplier s
)
SELECT 
    sm.uppercase_name,
    sm.lowercase_comment,
    sm.short_name,
    sm.comment_length,
    sd.supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price
FROM 
    StringManipulation sm
JOIN 
    lineitem l ON l.l_partkey = sm.p_partkey
JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    sm.comment_length > 10
GROUP BY 
    sm.uppercase_name, 
    sm.lowercase_comment, 
    sm.short_name, 
    sm.comment_length, 
    sd.supplier_info
ORDER BY 
    total_quantity DESC, 
    avg_extended_price DESC
LIMIT 100;
