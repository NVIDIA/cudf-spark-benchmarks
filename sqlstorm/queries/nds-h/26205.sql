SELECT 
    CONCAT(p.p_name, ' (', s.s_name, ') - ', r.r_name) AS product_supplier_region,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(l.l_orderkey) AS total_orders,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    SUM(l.l_discount) AS total_discount
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND p.p_comment LIKE '%fragile%'
GROUP BY 
    product_supplier_region
ORDER BY 
    total_quantity DESC, 
    average_price ASC
LIMIT 10;