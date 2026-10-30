
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN r.r_name LIKE '%AMERICA%' THEN 'Domestic'
        ELSE 'International' 
    END AS region_type,
    CONCAT('Processed ', COUNT(DISTINCT o.o_orderkey), ' orders for part: ', p.p_name) AS order_summary
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    customer c ON c.c_custkey = o.o_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01' 
    AND l.l_returnflag = 'N' 
GROUP BY 
    p.p_name, s.s_name, r.r_name 
ORDER BY 
    total_revenue DESC, total_quantity DESC 
LIMIT 10;
