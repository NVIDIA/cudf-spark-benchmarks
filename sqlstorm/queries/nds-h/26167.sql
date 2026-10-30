
SELECT 
    CONCAT_WS(' - ', p.p_name, s.s_name, CONCAT('Price: ', CAST(ROUND(p.p_retailprice, 2) AS STRING)), 
        CONCAT('Available Quantity: ', CAST(ps.ps_availqty AS STRING)), 
        CONCAT('Comment: ', ps.ps_comment)) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 
        (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment LIKE '%quality%')
GROUP BY 
    p.p_name, s.s_name, p.p_retailprice, ps.ps_availqty, ps.ps_comment
ORDER BY 
    p.p_name ASC, s.s_name DESC
LIMIT 100;
