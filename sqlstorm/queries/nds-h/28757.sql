
SELECT 
    p.p_name,
    s.s_name,
    SUBSTRING(s.s_address, 1, 20) AS short_address,
    CONCAT('Supplier ', s.s_name, ' offers ', p.p_name) AS supplier_offer,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price_per_line,
    MIN(l.l_discount) AS min_discount,
    MAX(l.l_tax) AS max_tax
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
    s.s_comment LIKE '%reliable%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address
HAVING 
    SUM(l.l_tax) > 1000
ORDER BY 
    total_quantity DESC, avg_price_per_line ASC
LIMIT 50;
