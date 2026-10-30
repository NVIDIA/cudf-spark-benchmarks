
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    SUBSTR(p.p_comment, 1, 10) AS short_comment, 
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    LEFT(COALESCE(s.s_comment, 'No Comment'), 50) AS supplier_comment_excerpt
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%steel%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, r.r_name, n.n_name, p.p_comment, s.s_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5 AND 
    AVG(l.l_extendedprice) > (SELECT AVG(l_extendedprice) FROM lineitem WHERE l_shipdate BETWEEN '1997-01-01' AND '1997-12-31')
ORDER BY 
    region_nation DESC, 
    avg_extended_price DESC;
