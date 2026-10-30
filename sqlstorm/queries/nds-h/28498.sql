SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_product,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_net_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    r.r_name AS region_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND p.p_brand LIKE 'Brand#%'
GROUP BY 
    supplier_product, r.r_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    avg_net_price DESC, total_orders DESC;