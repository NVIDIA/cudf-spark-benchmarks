
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND s.s_suppkey = l.l_suppkey
WHERE 
    p.p_size > 10 
    AND s.s_acctbal > 5000 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_comment, s.s_name, s.s_address
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC;
