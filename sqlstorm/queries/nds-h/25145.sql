
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    CONCAT('Supplied by ', s.s_name, ' to ', c.c_name) AS supply_customer_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE 'Rubber%'
    AND o.o_orderstatus = 'F'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_extendedprice) > 1000.00
ORDER BY 
    total_revenue DESC;
