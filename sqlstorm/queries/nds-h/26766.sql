SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    CONCAT('Supplier ', s.s_name, ' provides ', p.p_name) AS supplier_part_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%brass%' 
    AND s.s_comment NOT LIKE '%special%'
    AND o.o_orderdate > '1997-01-01'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    avg_extended_price DESC, max_discount ASC;