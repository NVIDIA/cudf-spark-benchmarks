SELECT 
    COUNT(DISTINCT c.c_custkey) AS unique_customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_open_orders,
    SUBSTRING(p.p_name, 1, 10) AS short_part_name,
    CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
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
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_acctbal > 500.00 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    short_part_name, supplier_info
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    unique_customer_count DESC, total_open_orders DESC;