
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUBSTRING(p.p_comment, 1, 20) AS truncated_comment,
    REGEXP_REPLACE(p.p_name, '(^\\s+|\\s+$)', '') AS trimmed_name,
    CASE 
        WHEN LENGTH(p.p_name) > 30 THEN 'LONG_NAME' 
        ELSE 'SHORT_NAME' 
    END AS name_length_category
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
    p.p_retailprice > 100.00
    AND s.s_acctbal > 2000.00
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, p.p_comment
HAVING 
    COUNT(l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 50;
