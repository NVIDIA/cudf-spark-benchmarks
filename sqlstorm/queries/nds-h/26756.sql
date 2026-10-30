SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS part_details,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY
    total_quantity DESC, region_name, nation_name;