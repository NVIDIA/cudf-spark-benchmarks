
SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(CAST(l.l_discount AS NUMERIC(5,2))) AS average_discount,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS location
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size >= 20
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, n.n_name, p.p_comment
HAVING 
    COUNT(o.o_orderkey) > 10
ORDER BY 
    total_revenue DESC
LIMIT 100;
