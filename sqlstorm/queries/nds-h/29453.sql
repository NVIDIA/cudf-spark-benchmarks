
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    COUNT(DISTINCT s.s_name) AS unique_suppliers,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    AVG(l.l_discount) AS average_discount_rate,
    REPLACE(n.n_name, ' ', '_') AS formatted_nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name, n.n_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
ORDER BY 
    average_discount_rate DESC, unique_suppliers ASC;
