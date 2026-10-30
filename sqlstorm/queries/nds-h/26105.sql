
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    l.l_quantity AS quantity,
    l.l_extendedprice AS extended_price,
    CASE 
        WHEN l.l_returnflag = 'Y' THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS return_status,
    CONCAT(s.s_address, ', ', n.n_name) AS supplier_location,
    CONCAT(c.c_address, ', ', n.n_name) AS customer_location,
    CAST(o.o_orderdate AS DATE) AS order_date
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_discount > 0.1 
    AND o.o_orderstatus = 'O'
    AND p.p_comment LIKE '%special%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, l.l_quantity, l.l_extendedprice, 
    l.l_returnflag, s.s_address, n.n_name, c.c_address, o.o_orderdate
ORDER BY 
    extended_price DESC
LIMIT 100;
