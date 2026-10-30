SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    CONCAT('Processed in ', r.r_name, ' with comment: ', r.r_comment) AS region_info,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Moderate Demand'
        ELSE 'Low Demand'
    END AS demand_category
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31' 
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, r.r_name, r.r_comment 
ORDER BY 
    total_quantity DESC, average_price DESC 
LIMIT 
    10;