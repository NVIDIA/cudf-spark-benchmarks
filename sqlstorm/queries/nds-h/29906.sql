SELECT 
    CONCAT(s.s_name, ' (', p.p_name, ')') AS supplier_part,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(l.l_discount) AS max_discount,
    SUBSTRING(r.r_comment, 1, 30) AS region_comment_snippet
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
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
    l.l_shipdate BETWEEN '1994-01-01' AND '1997-12-31'
      AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    supplier_part, r.r_name, r.r_comment
ORDER BY 
    total_quantity DESC, avg_price ASC
LIMIT 10;