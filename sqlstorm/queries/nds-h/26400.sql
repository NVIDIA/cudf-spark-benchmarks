
SELECT 
    p.p_name AS product_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUBSTRING(s.s_address, 1, 20) AS short_address,
    CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS region_nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND s.s_comment LIKE '%special%'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, n.n_name, s.s_address
ORDER BY 
    total_revenue DESC, order_count DESC
LIMIT 100;
