
SELECT 
    CONCAT(c.c_name, ' from ', r.r_name) AS supplier_info,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_quantity) AS average_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
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
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_type LIKE '%brass%'
    AND n.n_name IN (SELECT n2.n_name FROM nation n2 WHERE n2.n_regionkey = r.r_regionkey)
GROUP BY 
    c.c_name, r.r_name, p.p_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_sales DESC;
