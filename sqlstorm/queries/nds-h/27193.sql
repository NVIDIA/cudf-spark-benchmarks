
SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 10), '...', SUBSTRING(p.p_name, LENGTH(p.p_name) - 10, 10)) AS short_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_price,
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
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    CHAR_LENGTH(p.p_name) > 20
AND 
    o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
AND 
    p.p_brand LIKE 'Brand%'
GROUP BY 
    p.p_partkey, s.s_name, r.r_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, avg_price ASC;
