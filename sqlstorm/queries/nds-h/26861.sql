SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity * l.l_extendedprice) AS total_revenue,
    AVG(l.l_discount) AS avg_discount_rate,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    MAX(l.l_tax) AS max_tax_rate,
    SUBSTRING(MAX(p.p_comment), 1, 30) AS truncated_comment,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_quantity * l.l_extendedprice) DESC) AS revenue_rank
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_acctbal > 2000
GROUP BY 
    p.p_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 100
ORDER BY 
    total_revenue DESC;