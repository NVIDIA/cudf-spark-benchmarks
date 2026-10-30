SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    MAX(o.o_orderdate) AS last_order_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
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
    l.l_shipdate >= '1997-01-01' AND 
    l.l_shipdate < '1998-01-01' AND 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, r.r_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, last_order_date DESC;