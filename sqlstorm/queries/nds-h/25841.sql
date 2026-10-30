
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT(r.r_name, ': ', n.n_name) AS region_nation
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%rubber%'
    AND o.o_orderdate >= '1995-01-01'
    AND o.o_orderdate < '1996-01-01'
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC;
