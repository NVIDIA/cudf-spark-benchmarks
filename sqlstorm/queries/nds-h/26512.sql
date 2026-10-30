
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN LENGTH(p.p_comment) > 20 THEN 'Long Comment'
        ELSE 'Short Comment'
    END AS comment_length_category,
    TRIM(p.p_comment) AS trimmed_comment
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
    p.p_size BETWEEN 1 AND 10 
    AND s.s_acctbal > 1000.00 
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 50 
ORDER BY 
    total_revenue DESC;
