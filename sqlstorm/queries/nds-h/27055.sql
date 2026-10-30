
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%brass%'
    AND s.s_acctbal > 1000.00
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    p.p_name, n.n_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_supply_cost DESC, part_name ASC;
