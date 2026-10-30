SELECT 
    CONCAT(c.c_name, ' from ', n.n_name, ' in ', r.r_name) AS customer_info,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 20) AS brief_comment
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    c.c_name, n.n_name, r.r_name, p.p_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    total_revenue DESC
LIMIT 50;