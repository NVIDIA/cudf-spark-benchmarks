SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Cost: ', ROUND(ps.ps_supplycost, 2), ' | Available Quantity: ', ps.ps_availqty) AS benchmark_string
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    ps.ps_availqty > 50
    AND s.s_comment LIKE '%reliable%'
    AND p.p_type LIKE '%copper%'
ORDER BY 
    ps.ps_supplycost DESC
LIMIT 100;
