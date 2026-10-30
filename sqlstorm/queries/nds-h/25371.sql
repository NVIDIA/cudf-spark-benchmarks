
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_part_price,
    MAX(LENGTH(p.p_comment)) AS max_comment_length,
    MIN(CHAR_LENGTH(s.s_comment)) AS min_supplier_comment_length
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 0
GROUP BY 
    s.s_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 10
ORDER BY 
    average_part_price DESC,
    total_available_quantity ASC;
