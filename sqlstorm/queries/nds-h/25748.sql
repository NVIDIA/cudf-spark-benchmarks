SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Quantity: ', ps_availqty, 
           ', Price: $', ROUND(ps_supplycost, 2), ', Total Value: $', ROUND(ps_availqty * ps_supplycost, 2)) AS string_processing_benchmark
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
AND 
    ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
ORDER BY 
    ps_availqty DESC
LIMIT 10;
