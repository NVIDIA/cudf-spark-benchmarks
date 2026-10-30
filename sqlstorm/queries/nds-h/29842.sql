
SELECT 
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(s.s_acctbal) AS average_supplier_balance,
    SUBSTRING(p.p_comment, 1, 3) AS short_comment,
    CONCAT('Part: ', SUBSTRING(p.p_name, 1, 10), ' - Supplier: ', s.s_name) AS description
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%priority%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment, s.s_acctbal
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    total_orders DESC, average_supplier_balance DESC;
