SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Quantity Available: ', ps.ps_availqty) AS benchmark_string
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
    AND LENGTH(s.s_comment) > 50
ORDER BY 
    p.p_brand, s.s_name DESC
LIMIT 100;
