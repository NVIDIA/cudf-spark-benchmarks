
SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Available Quantity: ', ps.ps_availqty) AS details,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS total_returned_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
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
    p.p_comment LIKE '%special%'
    AND s.s_comment LIKE '%reliable%'
GROUP BY 
    s.s_name, p.p_name, ps.ps_availqty
HAVING 
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) > 1000
ORDER BY 
    total_returned_value DESC;
