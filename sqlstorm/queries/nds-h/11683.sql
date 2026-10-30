SELECT 
    COUNT(*) AS total_orders,
    SUM(o_totalprice) AS total_revenue,
    AVG(l_quantity) AS average_quantity,
    AVG(s_acctbal) AS average_supplier_balance
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
GROUP BY 
    r.r_name;
