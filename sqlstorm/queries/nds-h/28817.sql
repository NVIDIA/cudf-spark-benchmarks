
SELECT 
    SUBSTR(p.p_name, 1, 10) AS short_name,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region_info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_shipdate) AS earliest_shipping_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 15 AND
    l.l_shipmode IN ('AIR', 'MAIL') AND
    o.o_orderstatus = 'F'
GROUP BY 
    p.p_name, s.s_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
