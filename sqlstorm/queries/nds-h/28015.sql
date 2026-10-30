
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price,
    SUM(l.l_quantity) AS total_quantity,
    SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_supplier_comment,
    CONCAT('Region: ', r.r_name, ' - Supplier: ', s.s_name) AS region_supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_mktsegment = 'BUILDING'
    AND p.p_retailprice > 500.00
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, s.s_name, c.c_name, r.r_name, s.s_comment
ORDER BY 
    total_discounted_price DESC, total_quantity DESC;
