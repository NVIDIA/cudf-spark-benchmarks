SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN LENGTH(p.p_name) > 30 THEN 'Long Name' 
        ELSE 'Short Name' 
    END AS name_length_category,
    CONCAT('Order ', o.o_orderkey, ' contains ', l.l_quantity, ' of part ', p.p_name) AS order_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_brand LIKE 'BrandZ%' 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, l.l_quantity
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, name_length_category ASC;