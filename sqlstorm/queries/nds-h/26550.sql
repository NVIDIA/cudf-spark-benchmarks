SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Customer: ', c.c_name, 
           ', Total Quantity: ', SUM(l.l_quantity), 
           ', Date: ', CAST(o.o_orderdate AS STRING)) AS detail_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND p.p_size > 10 
    AND s.s_acctbal > 1000 
    AND c.c_mktsegment = 'Retail'
GROUP BY 
    s.s_name, p.p_name, c.c_name, o.o_orderdate
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_quantity DESC, supplier_name, part_name;