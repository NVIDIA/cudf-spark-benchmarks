SELECT 
    CONCAT(p.p_name, ' (', p.p_brand, ')') AS product_info,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(o.o_orderdate) AS last_order_date
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
    p.p_size > 10
    AND s.s_acctbal > 1000
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    product_info, supplier_name, customer_name
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 10;
