SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    SUM(l.l_extendedprice) AS total_sales,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_sales DESC
LIMIT 10;
