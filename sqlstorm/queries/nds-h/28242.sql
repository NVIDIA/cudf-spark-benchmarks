SELECT 
    p.p_name AS part_name, 
    CONCAT(SUBSTRING(p.p_comment, 1, 10), '...') AS short_comment,
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    p.p_size BETWEEN 5 AND 15 
    AND s.s_acctbal > 1000.00 
    AND o.o_orderdate >= DATE '1996-01-01'
GROUP BY 
    p.p_name, s.s_name, s.s_nationkey, p.p_comment
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_quantity DESC;