SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    l.l_tax,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS description
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_quantity > 10
    AND l.l_discount BETWEEN 0.05 AND 0.15
ORDER BY 
    r.r_name, n.n_name, s.s_name;