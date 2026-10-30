SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Nation: ', n.n_name) AS description,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_tax) AS max_tax
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    customer c ON l.l_orderkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
    AND p.p_retailprice > 100
GROUP BY 
    s.s_name, p.p_name, n.n_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC;