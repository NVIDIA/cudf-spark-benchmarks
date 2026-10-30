SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS average_price, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    LEFT(p.p_comment, 20) AS brief_comment, 
    r.r_name AS region_name,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Volume' 
        ELSE 'Low Volume' 
    END AS order_volume_category
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_retailprice > 10.00 
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31' 
    AND l.l_discount BETWEEN 0.05 AND 0.15 
GROUP BY 
    p.p_name, r.r_name, p.p_comment 
ORDER BY 
    total_quantity DESC, average_price ASC 
LIMIT 100;