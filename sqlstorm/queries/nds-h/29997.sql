
SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name) AS supplier_part_info,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    MAX(l.l_extendedprice) AS max_price,
    CASE 
        WHEN MAX(l.l_discount) > 0.1 THEN 'High Discount'
        ELSE 'Regular Pricing'
    END AS pricing_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > 1000 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_quantity DESC, supplier_part_info;
