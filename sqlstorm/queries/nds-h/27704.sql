
SELECT 
    p.p_partkey,
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation,
    s.s_name,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    COUNT(l.l_orderkey) AS total_lineitems,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, r.r_name, n.n_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
