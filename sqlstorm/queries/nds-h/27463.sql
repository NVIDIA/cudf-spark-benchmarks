
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_totalprice,
    COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_quantity) AS min_quantity,
    LEFT(p.p_comment, 10) AS short_comment,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region_info
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
    p.p_retailprice > 100.00 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_totalprice, p.p_comment, r.r_name
ORDER BY 
    total_extended_price DESC
LIMIT 50;
