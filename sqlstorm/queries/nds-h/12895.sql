SELECT 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(c.c_acctbal) AS average_customer_balance,
    MIN(s.s_acctbal) AS lowest_supplier_balance,
    t.p_type
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part t ON l.l_partkey = t.p_partkey
GROUP BY 
    t.p_type
ORDER BY 
    total_revenue DESC
LIMIT 10;
