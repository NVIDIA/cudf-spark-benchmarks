
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_shipdate) AS last_ship_date,
    SUBSTRING(s.s_comment, 1, 30) AS supplier_comment_excerpt,
    CONCAT('Total Revenue from ', p.p_name, ' by ', s.s_name, ': ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS DECIMAL(10, 2))) AS revenue_summary
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND o.o_orderstatus = 'O' 
GROUP BY 
    p.p_name, s.s_name, s.s_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC;
