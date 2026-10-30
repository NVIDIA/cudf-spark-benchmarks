SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Part: ', p.p_name) AS info_summary
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1997-10-01'
    AND p.p_type LIKE '%BRASS%'
GROUP BY 
    p.p_name, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC, avg_price_after_discount DESC;