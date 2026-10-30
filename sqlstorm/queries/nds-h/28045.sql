SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_number,
    l.l_quantity AS quantity_ordered,
    l.l_extendedprice AS extended_price,
    l.l_discount AS discount_amount,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Customer: ', c.c_name, ', Order No: ', o.o_orderkey) AS combined_info,
    LENGTH(CONCAT(l.l_comment, p.p_comment, s.s_comment)) AS total_comment_length,
    UPPER(substring(p.p_comment, 1, 10)) AS short_comment_upper,
    REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_supplier_comment,
    REPLACE(o.o_comment, '  ', ' ') AS cleaned_order_comment
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
    l.l_shipdate >= DATE '1997-01-01' AND 
    l.l_shipdate < DATE '1998-01-01' AND 
    l.l_returnflag = 'N' AND 
    p.p_retailprice > 100.00
ORDER BY 
    total_comment_length DESC
LIMIT 100;