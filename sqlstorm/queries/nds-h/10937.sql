SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
