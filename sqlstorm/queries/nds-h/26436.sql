
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(l.l_discount) AS avg_discount,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name
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
    p.p_retailprice > 10.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_acctbal >= 1000.00
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 500
ORDER BY 
    avg_discount DESC, unique_customers DESC;
