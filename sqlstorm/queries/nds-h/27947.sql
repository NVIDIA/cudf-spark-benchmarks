SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price, 
    CONCAT(r.r_name, ', ', n.n_name) AS region_nation 
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
    p.p_comment LIKE '%special%' 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31' 
GROUP BY 
    p.p_name, s.s_name, region_nation 
HAVING 
    SUM(ps.ps_availqty) > 500 
ORDER BY 
    avg_extended_price DESC 
LIMIT 10;