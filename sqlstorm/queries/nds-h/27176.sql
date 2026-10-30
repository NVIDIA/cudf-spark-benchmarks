
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS average_price,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name) AS part_supplier_info,
    RTRIM(p.p_comment) AS trimmed_comment
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
WHERE 
    o.o_orderdate >= DATE '1994-01-01' AND 
    o.o_orderdate < DATE '1995-01-01' AND 
    l.l_returnflag = 'N'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, p.p_comment
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_quantity DESC, average_price ASC;
