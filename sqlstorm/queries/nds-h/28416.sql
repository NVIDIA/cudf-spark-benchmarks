
SELECT 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(p.p_retailprice) AS average_part_price,
    SUBSTRING(p.p_name, 1, 20) AS short_part_name,
    LEFT(s.s_name, 10) AS supplier_prefix,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    LENGTH(p.p_comment) AS comment_length
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%EUROPE%'
    AND l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    r.r_name, n.n_name, SUBSTRING(p.p_name, 1, 20), LEFT(s.s_name, 10), LENGTH(p.p_comment)
ORDER BY 
    total_revenue DESC;
