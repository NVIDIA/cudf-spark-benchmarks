SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    SUM(line.l_quantity) AS total_quantity, 
    SUM(line.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    lineitem line ON p.p_partkey = line.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name = 'USA'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_revenue DESC
LIMIT 10;
