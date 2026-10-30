
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    CONCAT(p.p_name, ' supplied by ', s.s_name, ' from ', n.n_name, ' with a retail price of ', CAST(p.p_retailprice AS DECIMAL(10, 2))) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_name, s.s_name, n.n_name, p.p_retailprice
ORDER BY 
    p.p_name, s.s_name;
