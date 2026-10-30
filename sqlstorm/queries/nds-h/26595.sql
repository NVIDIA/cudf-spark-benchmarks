SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    l.l_quantity,
    CASE 
        WHEN l.l_discount > 0.05 THEN 'High Discount'
        ELSE 'Regular Discount'
    END AS discount_category,
    CONCAT('Part name: ', p.p_name, ', ordered by: ', c.c_name) AS order_description,
    LEFT(p.p_comment, 15) AS short_comment
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    p.p_type LIKE '%metal%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    l.l_quantity DESC, 
    discount_category;