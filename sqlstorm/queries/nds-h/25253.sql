
SELECT 
    CONCAT_WS(' ', p.p_name, '(', p.p_size, ')') AS part_description,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    n.n_name AS nation_name
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_comment LIKE '%urgent%'
    AND o.o_orderdate BETWEEN DATE('1997-01-01') AND DATE('1997-12-31')
    AND s.s_comment LIKE '%quality%'
GROUP BY 
    p.p_name, p.p_size, s.s_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
