SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, 
           ', Availability: ', ps_availqty, ', Cost: $', ps_supplycost, 
           ', Comment: ', ps_comment) AS detailed_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(s_name) > 10 AND 
    UPPER(p_brand) LIKE 'A%' AND 
    ps_availqty > 0 AND 
    ps_supplycost < (
        SELECT AVG(ps_supplycost) 
        FROM partsupp 
        WHERE ps_availqty > 0
    )
ORDER BY 
    p_name, s_name
LIMIT 100;
