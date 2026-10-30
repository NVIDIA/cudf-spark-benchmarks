SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Part Type: ', p.p_type, ', Average Supply Cost: ', AVG(ps.ps_supplycost)) AS supplier_part_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    LEFT(p.p_comment, 10) AS short_comment
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
WHERE 
    p.p_size > 20 
    AND s.s_acctbal > 1000.00 
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_name, s.s_name, p.p_type, p.p_comment
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
