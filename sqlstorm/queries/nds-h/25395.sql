SELECT 
    s.s_name AS supplier_name, 
    CONCAT(p.p_name, ' - ', p.p_brand, ' (', p.p_container, ')') AS part_description,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, p.p_brand, p.p_container
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    revenue_rank
LIMIT 10;