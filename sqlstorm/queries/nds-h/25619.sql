
SELECT 
    p.p_name, 
    s.s_name, 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    SUBSTRING(UPPER(p.p_comment) FROM 1 FOR 20) AS short_comment, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers 
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name, o.o_orderkey, p.p_comment 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 
ORDER BY 
    total_revenue DESC;
