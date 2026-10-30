
SELECT 
    CONCAT('Provider: ', s.s_name, ' | Product: ', p.p_name, ' | Nation: ', n.n_name) AS description,
    SUM(ps.ps_availqty) AS total_available,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_value,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%quality%'
    AND s.s_comment NOT LIKE '%excellent%'
GROUP BY 
    s.s_name, p.p_name, n.n_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    avg_order_value DESC, last_order_date ASC
LIMIT 10;
