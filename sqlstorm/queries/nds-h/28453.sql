SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    l.l_quantity,
    l.l_extendedprice,
    CASE 
        WHEN l.l_discount > 0.1 THEN 'Discounted'
        ELSE 'Regular Price'
    END AS pricing_category,
    CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Customer: ', c.c_name) AS description,
    LENGTH(l.l_comment) AS comment_length
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
    p.p_brand LIKE 'Brand#%'
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    p.p_name,
    s.s_name,
    c.c_name;