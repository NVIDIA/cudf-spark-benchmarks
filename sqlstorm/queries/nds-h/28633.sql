SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND p.p_size IN (10, 20, 30)
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, s.s_name, short_comment, nation_region
ORDER BY 
    revenue DESC, order_count DESC
LIMIT 100;