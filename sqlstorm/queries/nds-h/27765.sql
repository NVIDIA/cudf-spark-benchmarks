
SELECT 
    p.p_name, 
    s.s_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    MAX(l.l_discount) AS max_discount,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS location_description
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND p.p_brand LIKE '%Brand%'
GROUP BY 
    p.p_name, s.s_name, r.r_name, n.n_name, p.p_comment
ORDER BY 
    customer_count DESC, total_quantity DESC
LIMIT 50;
