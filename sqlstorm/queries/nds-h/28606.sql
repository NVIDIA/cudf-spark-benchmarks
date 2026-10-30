
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderdate AS order_date, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name,
    TRIM(CONCAT('Order #', o.o_orderkey, ' by ', c.c_name, ' for ', s.s_name, ' of ', p.p_name)) AS order_summary
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    o.o_orderstatus = 'O' 
    AND p.p_retailprice > 50.00 
    AND n.n_name LIKE 'A%' 
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderdate, r.r_name, o.o_orderkey, c.c_name, s.s_name, p.p_name 
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    total_revenue DESC, order_date ASC;
