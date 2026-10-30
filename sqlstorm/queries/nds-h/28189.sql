SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_discount) AS average_discount, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CONCAT(c.c_name, ' (', s.s_name, ')') AS customer_supplier_details,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 100 THEN 'High Frequency'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 50 AND 100 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END AS order_frequency
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_name, c.c_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, average_discount ASC;
