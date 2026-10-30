
SELECT 
    p.p_name,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Brand: ', p.p_brand, ' - Type: ', p.p_type) AS product_info,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%Asia%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_comment, p.p_brand, p.p_type, LENGTH(p.p_comment), CONCAT('Brand: ', p.p_brand, ' - Type: ', p.p_type)
HAVING 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) > 0
ORDER BY 
    avg_price_after_discount DESC, comment_length ASC;
