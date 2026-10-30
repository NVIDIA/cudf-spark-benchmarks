SELECT 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice) AS avg_extended_price,
    AVG(s.s_acctbal) AS avg_supplier_balance
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
GROUP BY 
    c.c_nationkey 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
