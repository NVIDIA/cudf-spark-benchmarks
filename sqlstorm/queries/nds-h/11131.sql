SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(o.o_orderkey) AS order_count
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
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    total_available DESC, avg_extended_price DESC
LIMIT 100;
