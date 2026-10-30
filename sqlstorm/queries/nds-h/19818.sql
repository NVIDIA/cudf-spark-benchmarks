SELECT p_name, SUM(ps_supplycost * ps_availqty) AS total_cost 
FROM part 
JOIN partsupp ON p_partkey = ps_partkey 
GROUP BY p_name 
ORDER BY total_cost DESC 
LIMIT 10;
