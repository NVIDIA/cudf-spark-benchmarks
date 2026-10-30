
SELECT 
    CONCAT(s.s_name, ' from ', r.r_name) AS supplier_region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTR(p.p_name, 1, 10) AS short_part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_comment LIKE '%reliable%'
GROUP BY 
    s.s_name, r.r_name, short_part_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC;
