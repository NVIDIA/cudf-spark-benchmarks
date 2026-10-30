
SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
    p.p_retailprice < 50.00 
    AND s.s_acctbal > 1000.00 
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 200
ORDER BY 
    average_price DESC,
    total_quantity ASC;
