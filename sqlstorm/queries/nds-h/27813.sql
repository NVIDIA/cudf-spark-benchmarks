SELECT  
    p.p_name, 
    s.s_name, 
    c.c_name, 
    o.o_orderkey, 
    l.l_quantity, 
    l.l_extendedprice, 
    CONCAT('Supplier: ', s.s_name, ', Customer: ', c.c_name, ', Part: ', p.p_name) AS order_details,
    REPLACE(p.p_comment, 'old', 'new') AS updated_comment,
    LENGTH(p.p_name) AS name_length,
    CASE 
        WHEN l.l_quantity > 100 THEN 'High'
        WHEN l.l_quantity BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS quantity_category
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
    part p ON ps.ps_partkey = p.p_partkey 
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
    AND l.l_discount > 0.05 
ORDER BY 
    name_length DESC, 
    quantity_category ASC;