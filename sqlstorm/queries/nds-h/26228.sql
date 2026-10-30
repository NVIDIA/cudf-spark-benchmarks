
SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Type: ', p.p_type) AS product_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    CHAR_LENGTH(p.p_name) > 10
    AND p.p_retailprice > 100.00
GROUP BY 
    p.p_name, p.p_mfgr, p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_price DESC;
