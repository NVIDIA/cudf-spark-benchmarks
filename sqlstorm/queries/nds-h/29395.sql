SELECT 
    p.p_name, 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT c.c_custkey) AS total_customers, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Quantity Sold: ', SUM(l.l_quantity)) AS benchmark_string
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_type LIKE '%brass%' 
    AND s.s_acctbal > 1000.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;