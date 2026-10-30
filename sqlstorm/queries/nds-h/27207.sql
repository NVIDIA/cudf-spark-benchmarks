SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_price_per_unit,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    CONCAT('Item: ', p.p_name, ' | Quantity: ', CAST(SUM(l.l_quantity) AS STRING), ' | Orders: ', CAST(COUNT(DISTINCT o.o_orderkey) AS STRING)) AS item_summary
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderstatus = 'F'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;