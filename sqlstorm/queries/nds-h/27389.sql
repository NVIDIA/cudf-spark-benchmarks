SELECT 
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Region: ', r_name) AS detailed_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    AVG(s_acctbal) AS avg_supplier_balance
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;