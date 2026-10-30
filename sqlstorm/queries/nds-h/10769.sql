SELECT 
    ps_partkey, 
    SUM(ps_availqty) AS total_availqty, 
    AVG(ps_supplycost) AS avg_supplycost 
FROM 
    partsupp 
GROUP BY 
    ps_partkey 
ORDER BY 
    total_availqty DESC 
LIMIT 10;
