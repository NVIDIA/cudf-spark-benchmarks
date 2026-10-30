SELECT 
    p.p_name, 
    p.p_brand, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate,
    CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Supplier: ', s.s_name) AS part_supplier_info,
    LENGTH(CONCAT(p.p_name, s.s_name)) AS combined_length,
    LOWER(TRIM(p.p_comment)) AS normalized_comment,
    REPLACE(UPPER(p.p_comment), ' ', '_') AS underscore_comment
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice > 100.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    combined_length DESC, 
    normalized_comment ASC
LIMIT 100;