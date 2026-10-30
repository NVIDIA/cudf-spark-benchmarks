
SELECT 
    substring(p.p_name, 1, 10) AS short_name,
    concat(s.s_name, ' - ', c.c_name) AS supplier_customer,
    count(DISTINCT o.o_orderkey) AS order_count,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_type LIKE '%rubber%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    substring(p.p_name, 1, 10), 
    concat(s.s_name, ' - ', c.c_name), 
    r.r_name
HAVING 
    sum(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
