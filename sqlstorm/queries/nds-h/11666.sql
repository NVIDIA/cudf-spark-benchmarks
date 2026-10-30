SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
    total_supplycost DESC
LIMIT 10;
