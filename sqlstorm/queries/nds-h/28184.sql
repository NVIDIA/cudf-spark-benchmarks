
SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_nationkey) AS unique_nations,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customer_names,
    MAX(o.o_totalprice) AS max_order_price,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Total:', CAST(SUM(l.l_quantity) AS STRING), ' - Avg Price:', CAST(AVG(l.l_discount) AS STRING)) AS summary
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_type LIKE '%brass%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name,
    p.p_comment
HAVING 
    SUM(l.l_quantity) > 1000
ORDER BY 
    unique_nations DESC, 
    avg_extended_price DESC;
