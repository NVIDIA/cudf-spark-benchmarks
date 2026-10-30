
SELECT 
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation, 
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_ordered_value,
    AVG(l.l_extendedprice) AS avg_lineitem_price,
    MAX(SUBSTRING(p.p_comment, 1, 15)) AS max_comment_snippet
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_ordered_value DESC, region_nation;
