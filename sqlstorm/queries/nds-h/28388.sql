SELECT 
    p.p_name, 
    CONCAT(SUBSTRING(p.p_comment, 1, 20), '...') AS truncated_comment,
    s.s_name, 
    c.c_name, 
    o.o_orderdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100.00
    AND s.s_acctbal > 500.00
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    p.p_name, truncated_comment, s.s_name, c.c_name, o.o_orderdate
ORDER BY 
    total_revenue DESC
LIMIT 10;