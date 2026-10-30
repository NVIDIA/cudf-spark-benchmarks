SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(ls.l_quantity) AS total_quantity,
    SUM(ls.l_extendedprice) AS total_revenue,
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem ls ON p.p_partkey = ls.l_partkey
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
GROUP BY 
    p.p_partkey, p.p_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 100;