SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
    AVG(l.l_quantity) AS avg_quantity, 
    MAX(l.l_extendedprice) AS max_price, 
    MIN(l.l_discount) AS min_discount, 
    CONCAT('Region: ', r.r_name, ' | Supplier: ', s.s_name, ' | Customer: ', c.c_name) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE 'rubber%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
ORDER BY 
    total_sales DESC, avg_quantity ASC
LIMIT 50;