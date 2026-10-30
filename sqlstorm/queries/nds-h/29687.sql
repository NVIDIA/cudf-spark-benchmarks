SELECT 
    p.p_name AS part_name,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    LEFT(r.r_name, 3) AS region_prefix,
    CONCAT('Supplier: ', s.s_name, ' | Qty: ', ps.ps_availqty) AS supplier_info
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
    p.p_name LIKE 'Steel%'
GROUP BY 
    p.p_name, r.r_name, s.s_name, ps.ps_availqty
HAVING 
    AVG(l.l_extendedprice) > 500
ORDER BY 
    avg_price DESC, part_name ASC;
