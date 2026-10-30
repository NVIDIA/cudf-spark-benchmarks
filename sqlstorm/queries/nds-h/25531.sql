
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    COUNT(o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    SUM(l.l_quantity) AS total_quantity_sold,
    RTRIM(CONCAT(s.s_name, ' - ', p.p_name, ' - ', c.c_name)) AS detailed_info,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    p.p_comment LIKE '%widget%' 
    AND s.s_comment NOT LIKE '%bad supplier%' 
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31' 
GROUP BY 
    p.p_name, s.s_name, c.c_name, p.p_partkey, s.s_suppkey, c.c_custkey 
HAVING 
    SUM(l.l_quantity) > 50 
ORDER BY 
    total_revenue DESC;
