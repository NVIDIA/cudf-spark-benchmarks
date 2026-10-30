SELECT 
    CONCAT('Supplier Name: ', s_name) AS supplier_info,
    REPLACE(s_address, ', ', ' | ') AS formatted_address,
    LENGTH(s_comment) AS comment_length,
    s_acctbal,
    LEFT(s_phone, 3) AS area_code,
    (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s_suppkey) AS supply_count
FROM 
    supplier s
WHERE 
    s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    comment_length DESC, 
    supply_count DESC
LIMIT 10;
