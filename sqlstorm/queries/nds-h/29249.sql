
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    n.n_name AS nation_name, 
    l.l_quantity * l.l_extendedprice AS revenue, 
    SUBSTR(l.l_comment, 1, 30) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS order_count
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, n.n_name, l.l_quantity, l.l_extendedprice, l.l_comment
ORDER BY 
    revenue DESC 
LIMIT 10;
