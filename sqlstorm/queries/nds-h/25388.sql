SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer_info,
    SUBSTRING(p.p_name, 1, 20) AS short_part_name,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    part p ON l.l_partkey = p.p_partkey
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND s.s_acctbal > 1000.00 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    supplier_customer_info, short_part_name, p.p_type
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000.00
ORDER BY 
    total_revenue DESC;