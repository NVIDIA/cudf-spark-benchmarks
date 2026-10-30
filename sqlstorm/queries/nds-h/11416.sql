SELECT 
    p_name, 
    COUNT(DISTINCT ps_suppkey) AS supplier_count, 
    SUM(ps_availqty) AS total_avail_qty, 
    AVG(ps_supplycost) AS avg_supply_cost 
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey 
GROUP BY 
    p_name 
ORDER BY 
    total_avail_qty DESC 
LIMIT 10;
