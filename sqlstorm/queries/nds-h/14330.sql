SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    s.s_acctbal, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_acctbal
ORDER BY 
    total_extended_price DESC
LIMIT 100;
