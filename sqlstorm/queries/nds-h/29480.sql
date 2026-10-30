SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 15), '...', CONCAT(' (', s.s_name, ')')) AS part_details,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    c.c_mktsegment AS market_segment,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
AND 
    LENGTH(p.p_comment) > 10
GROUP BY 
    part_details, market_segment, region_name
ORDER BY 
    total_revenue DESC
LIMIT 10;