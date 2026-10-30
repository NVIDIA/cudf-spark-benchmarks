SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer, 
    SUBSTRING(p.p_name, 1, 20) AS truncated_part_name, 
    p.p_brand, 
    REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_supplier_comment,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Revenue'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    lineitem l 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00 
    AND l.l_shipdate >= '1997-01-01' 
GROUP BY 
    c.c_name, s.s_name, p.p_name, p.p_brand, s.s_comment 
ORDER BY 
    total_revenue DESC 
LIMIT 10;