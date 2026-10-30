SELECT 
    s.s_name AS supplier_name,
    CONCAT('Supplier ', s.s_name, ' provides parts of type ', p.p_type, ' with a price greater than $', CAST(p.p_retailprice AS STRING), ' and is located in nation ', n.n_name) AS description,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    s.s_name, p.p_type, p.p_retailprice, n.n_name
ORDER BY 
    total_parts_supplied DESC, total_supply_cost ASC
LIMIT 10;
