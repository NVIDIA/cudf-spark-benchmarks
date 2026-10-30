
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT l.l_linenumber) AS lineitem_count
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
WHERE 
    o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
    AND o.o_orderstatus = 'O'
    AND n.n_name IN (SELECT r_name FROM region WHERE r_regionkey = 1)
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
