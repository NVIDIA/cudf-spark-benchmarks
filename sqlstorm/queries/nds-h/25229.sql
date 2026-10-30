
SELECT 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    region.r_name AS region_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Comments: ', p.p_comment, ' | ', s.s_comment, ' | ', c.c_comment) AS combined_comments
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
    region ON n.n_regionkey = region.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
AND 
    p.p_retailprice > 10.00
GROUP BY 
    p.p_name, s.s_name, c.c_name, region.r_name, p.p_comment, s.s_comment, c.c_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;
