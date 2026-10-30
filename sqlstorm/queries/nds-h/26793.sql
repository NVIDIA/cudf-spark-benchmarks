SELECT 
    CONCAT(SUBSTRING(p_name, 1, 10), '...', 
           SUBSTRING(REPLACE(p_comment, 'bad', 'good'), 1, 10), '...') AS part_summary, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    ROUND(AVG(ps_supplycost), 2) AS average_supply_cost,
    RANK() OVER (ORDER BY ROUND(AVG(ps_supplycost), 2) DESC) AS cost_rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 15
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_supply_cost DESC
LIMIT 10;
