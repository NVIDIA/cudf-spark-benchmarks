SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    COUNT(*) AS total_orders, 
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE WHEN o.o_orderstatus = 'O' THEN c.c_acctbal ELSE NULL END) AS avg_active_customer_balance
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%steel%'
    AND s.s_address NOT LIKE '%test%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, 
    s.s_name, 
    c.c_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_revenue DESC, 
    total_orders DESC
LIMIT 10;