
SELECT 
    p.p_partkey,
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice) DESC) AS rank_by_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND r.r_name LIKE 'Asia%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, p.p_type
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    rank_by_revenue, total_orders DESC;
