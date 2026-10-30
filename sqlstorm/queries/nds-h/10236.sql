SELECT 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice) AS avg_lineitem_price,
    COUNT(DISTINCT p.p_partkey) AS unique_parts
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
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1997-10-01'
GROUP BY 
    c.c_nationkey
ORDER BY 
    total_revenue DESC;