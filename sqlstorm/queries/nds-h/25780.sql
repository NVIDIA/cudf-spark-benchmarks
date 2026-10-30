
SELECT 
    CONCAT(s.s_name, ' from ', n.n_name, ', ', r.r_name) AS supplier_location,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    MAX(l.l_tax) AS max_tax,
    SUBSTRING(s.s_comment, 1, 20) AS supplier_comment_excerpt
FROM 
    supplier s 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    r.r_name LIKE 'Asia%' 
    AND l.l_shipmode IN ('AIR', 'RAIL') 
    AND o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    s.s_name, n.n_name, r.r_name, s.s_comment
ORDER BY 
    total_revenue DESC
LIMIT 10;
