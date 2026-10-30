SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    COUNT(o.o_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity_sold, 
    AVG(l.l_extendedprice) AS avg_price_per_item, 
    CONCAT(n.n_name, ' (', r.r_name, ')') AS nation_region
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    customer c ON c.c_custkey = o.o_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_comment LIKE '%quality%' 
    AND s.s_comment NOT LIKE '%substandard%' 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
GROUP BY 
    p.p_name, s.s_name, n.n_name, r.r_name 
HAVING 
    COUNT(o.o_orderkey) > 5 
ORDER BY 
    total_quantity_sold DESC, avg_price_per_item ASC;