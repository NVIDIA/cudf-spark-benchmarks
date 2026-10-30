SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    s.s_name, 
    s.s_acctbal, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, s.s_name, s.s_acctbal
ORDER BY 
    total_revenue DESC
LIMIT 10;