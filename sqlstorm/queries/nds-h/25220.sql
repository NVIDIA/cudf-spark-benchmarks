SELECT 
    p.p_name,
    p.p_brand,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales_price,
    r.r_name AS region_name,
    SUBSTRING(s.s_name, 1, 10) AS short_supplier_name,
    CONCAT(c.c_name, ' - ', c.c_mktsegment) AS customer_details
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, r.r_name, s.s_name, c.c_name, c.c_mktsegment
ORDER BY 
    total_orders DESC, avg_sales_price DESC;