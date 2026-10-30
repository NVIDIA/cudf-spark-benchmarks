SELECT 
    SUBSTR(p.p_name, 1, 20) AS short_name,
    REPLACE(p.p_comment, 'bad', 'good') AS updated_comment,
    CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info,
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
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 5000 
    AND o.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    short_name, updated_comment, supplier_info
ORDER BY 
    order_count DESC, avg_extended_price DESC;