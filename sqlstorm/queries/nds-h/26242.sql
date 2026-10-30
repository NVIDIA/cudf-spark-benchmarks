
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(s.s_comment, 1, 20) AS short_comment,
    REPLACE(REPLACE(l.l_shipmode, 'AIR', 'A'), 'GROUND', 'G') AS shipping_mode,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, s.s_name, SUBSTRING(s.s_comment, 1, 20), 
    REPLACE(REPLACE(l.l_shipmode, 'AIR', 'A'), 'GROUND', 'G')
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
