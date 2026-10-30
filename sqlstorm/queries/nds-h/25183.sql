SELECT 
    p.p_name,
    p.p_brand,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    MAX(l.l_tax) AS max_tax,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT(n.n_name, ' - ', r.r_name) AS nation_region
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
    p.p_comment LIKE '%distributor%'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, s.s_name, n.n_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_price DESC, total_quantity DESC;