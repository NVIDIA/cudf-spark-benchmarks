
SELECT 
    p.p_name,
    s.s_name,
    n.n_name,
    LEFT(s.s_address, POSITION(',' IN s.s_address) - 1) AS city,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%steel%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND s.s_acctbal > 5000
GROUP BY 
    p.p_name, s.s_name, n.n_name, LEFT(s.s_address, POSITION(',' IN s.s_address) - 1)
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_quantity DESC, avg_price ASC;
