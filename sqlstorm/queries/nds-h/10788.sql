SELECT 
    ps_partkey, 
    SUM(ps_availqty) AS total_available_quantity, 
    SUM(ps_supplycost) AS total_supply_cost
FROM 
    partsupp
GROUP BY 
    ps_partkey
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
