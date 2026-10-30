
SELECT 
    p.p_name, 
    p.p_mfgr, 
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CASE 
        WHEN SUM(ps.ps_availqty) = 0 THEN 'Out of Stock'
        WHEN AVG(l.l_extendedprice * (1 - l.l_discount)) > 100 THEN 'Premium Product'
        ELSE 'Standard Product'
    END AS product_status
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND p.p_comment LIKE '%fragile%'
    AND s.s_comment NOT LIKE '%bad supplier%'
GROUP BY 
    p.p_name, 
    p.p_mfgr, 
    s.s_name
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_orders DESC, 
    avg_sales_price DESC
LIMIT 100;
