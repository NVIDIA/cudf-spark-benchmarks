SELECT 
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers
FROM 
    customer c 
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1997-12-31'
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 500000
ORDER BY 
    total_revenue DESC;