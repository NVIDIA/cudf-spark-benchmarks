
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    CONCAT(s.s_address, ', ', r.r_name) AS supplier_address, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE NULL END) AS avg_returned_qty 
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
    AND s.s_comment NOT LIKE '%discount%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name, s.s_address, r.r_name 
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 
ORDER BY 
    total_revenue DESC;
