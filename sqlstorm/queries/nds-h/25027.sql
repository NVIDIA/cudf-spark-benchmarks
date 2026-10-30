
SELECT 
    CONCAT('Nation: ', n.n_name, ', Supplier: ', s.s_name, ', Part: ', p.p_name) AS info,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
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
WHERE 
    n.n_name LIKE 'A%' AND 
    s.s_comment LIKE '%credible%' AND 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    n.n_name, s.s_name, p.p_name, n.n_nationkey, s.s_suppkey, p.p_partkey
ORDER BY 
    total_revenue DESC,
    total_customers ASC;
