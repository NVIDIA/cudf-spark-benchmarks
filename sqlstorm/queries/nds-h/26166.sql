SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost) DESC) AS type_rank
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
    LENGTH(p.p_name) > 5 
    AND p.p_comment LIKE '%quality%'
    AND r.r_name IN ('ASIA', 'EUROPE')
GROUP BY 
    p.p_partkey, p.p_name, p.p_type
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    avg_retail_price DESC 
LIMIT 10;
