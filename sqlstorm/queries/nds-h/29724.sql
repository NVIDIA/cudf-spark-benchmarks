SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT_WS(', ', c.c_name, c.c_address) AS customer_info, 
    SUBSTRING(o.o_orderstatus FROM 1 FOR 1) AS order_status,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(o.o_orderdate) AS last_order_date,
    AVG(c.c_acctbal) AS average_account_balance
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
    LENGTH(p.p_name) > 10 
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE UPPER(n.n_name) LIKE 'A%')
GROUP BY 
    p.p_name, s.s_name, customer_info, order_status
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_revenue DESC, last_order_date DESC;
