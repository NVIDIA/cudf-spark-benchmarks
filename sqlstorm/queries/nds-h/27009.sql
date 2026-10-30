SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Item: ', p.p_name, ' | Supplier: ', s.s_name, ' | Total Available: ', SUM(ps.ps_availqty), ' | Avg Price: ', AVG(l.l_extendedprice)) AS summary
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_retailprice > 50.00
    AND s.s_acctbal > 10000.00
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_available_quantity DESC, average_extended_price ASC;