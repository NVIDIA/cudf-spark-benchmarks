SELECT 
    p.p_name AS part_name,
    SUBSTRING(p.p_comment, 1, 20) AS comment_excerpt,
    s.s_name AS supplier_name,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(l.l_extendedprice) AS average_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_brand LIKE 'Brand%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name, p.p_comment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    average_price DESC
LIMIT 50;