SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(l.l_quantity) AS average_quantity,
    MAX(CAST(l.l_shipdate AS DATE)) AS last_ship_date
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
    s.s_comment LIKE '%special%' 
    AND p.p_type = 'SIMPLE BRONZE'
GROUP BY 
    supplier_part
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
ORDER BY 
    revenue DESC
LIMIT 5;
