SELECT 
    CONCAT(c.c_name, ' (', s.s_name, ')') AS customer_supplier,
    p.p_name AS part_name,
    CONCAT('Order Status: ', o.o_orderstatus, ', Priority: ', o.o_orderpriority) AS order_details,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_discount) AS min_discount
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
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_brand LIKE 'Brand%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, s.s_name, p.p_name, o.o_orderstatus, o.o_orderpriority
ORDER BY 
    total_quantity DESC, avg_price_after_discount DESC
LIMIT 100;