SELECT 
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN AVG(l.l_discount) > 0.1 THEN 'High Discount'
        WHEN AVG(l.l_discount) BETWEEN 0.05 AND 0.1 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    CONCAT(r.r_name, ': ', n.n_name) AS region_nation
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
GROUP BY 
    p.p_name, r.r_name, n.n_name
ORDER BY 
    total_quantity DESC, avg_price DESC
LIMIT 10;