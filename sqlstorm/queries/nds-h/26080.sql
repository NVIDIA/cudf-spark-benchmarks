
SELECT 
    CONCAT_WS(' ', c.c_name, c.c_address) AS customer_info,
    p.p_name AS part_name,
    ps.ps_availqty AS available_quantity,
    s.s_name AS supplier_name,
    CONCAT(s.s_phone, ' - ', s.s_comment) AS supplier_details,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_value
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'U%')
GROUP BY 
    c.c_name, c.c_address, p.p_name, ps.ps_availqty, s.s_name, s.s_phone, s.s_comment
HAVING 
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_value DESC
LIMIT 10;
