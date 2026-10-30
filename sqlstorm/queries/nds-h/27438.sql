
SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT(NATION.n_name, ' - ', REGION.r_name) AS location
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey 
JOIN 
    nation NATION ON s.s_nationkey = NATION.n_nationkey 
JOIN 
    region REGION ON NATION.n_regionkey = REGION.r_regionkey 
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, NATION.n_name, REGION.r_name
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    total_orders DESC, total_quantity DESC;
