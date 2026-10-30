SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Region: ', r.r_name, ', Comment: ', r.r_comment) AS region_info
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
    p.p_name LIKE '%Steel%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, c.c_name, r.r_name, r.r_comment 
ORDER BY 
    total_quantity DESC, average_price DESC
LIMIT 100;