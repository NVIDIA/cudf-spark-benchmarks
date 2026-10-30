SELECT 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice) AS avg_lineitem_price,
    MIN(p.p_retailprice) AS min_part_price,
    MAX(p.p_retailprice) AS max_part_price
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    c.c_name
ORDER BY 
    total_revenue DESC
LIMIT 100;
