SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(o.o_totalprice) AS avg_order_price,
    REGEXP_REPLACE(p.p_comment, '(\s+)', ' ') AS cleaned_comment,
    CONCAT('Part: ', p.p_name, ' | Suppliers: ', COUNT(DISTINCT ps.ps_suppkey),
           ' | Total Quantity: ', SUM(l.l_quantity),
           ' | Avg Order Price: ', AVG(o.o_totalprice)) AS summary
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 50.00
AND 
    o.o_orderstatus = 'O'
AND 
    LENGTH(p.p_comment) > 10
GROUP BY 
    p.p_name, cleaned_comment
ORDER BY 
    total_quantity DESC
LIMIT 10;
