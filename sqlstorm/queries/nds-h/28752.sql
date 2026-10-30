SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    r.r_name AS region,
    n.n_name AS nation
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%Steel%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, p.p_type, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_quantity DESC, avg_price DESC;