
SELECT 
    CONCAT_WS(' - ', p.p_name, s.s_name, n.n_name) AS product_supplier_nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    MAX(s.s_acctbal) AS max_supplier_balance,
    MIN(l.l_tax) AS min_tax
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_container LIKE '%BOX%'
    AND n.n_name IN (SELECT n2.n_name FROM nation n2 WHERE n2.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
