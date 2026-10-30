SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS full_description,
    LENGTH(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name)) AS description_length,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(l.l_extendedprice) AS max_price,
    MIN(l.l_extendedprice) AS min_price,
    AVG(l.l_extendedprice) AS avg_price,
    TRIM(CONCAT('Total', ' ', SUM(l.l_extendedprice))) AS total_extended_price
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
    s.s_comment LIKE '%fragile%'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    AVG(l.l_extendedprice) > 100
ORDER BY 
    description_length DESC;
