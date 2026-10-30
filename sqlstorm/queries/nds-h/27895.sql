SELECT 
    p.p_name,
    CONCAT(s.s_name, ' from ', n.n_name, ' in ', r.r_name) AS supplier_location,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    CASE 
        WHEN AVG(l.l_extendedprice * (1 - l.l_discount)) > 100 THEN 'High Value'
        WHEN AVG(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
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
WHERE 
    p.p_name LIKE '%widget%' AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name
ORDER BY 
    total_orders DESC, avg_price_after_discount DESC;