
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(l.l_discount) AS avg_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name,
    n.n_name
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE 'BRASS%' 
    AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    avg_discount DESC, unique_customers ASC;
