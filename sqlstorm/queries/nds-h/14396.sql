SELECT 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_brand, 
    p.p_type
ORDER BY 
    total_avail_qty DESC
LIMIT 10;
