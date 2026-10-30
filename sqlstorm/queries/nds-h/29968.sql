
SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    MIN(l.l_discount) AS min_discount,
    MAX(l.l_tax) AS max_tax,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT('Supplier: ', s.s_name, ', Quantity: ', SUM(l.l_quantity), ', Average Price: ', AVG(l.l_extendedprice)) AS detailed_info
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
    p.p_retailprice > 100.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    total_quantity DESC, average_price ASC;
