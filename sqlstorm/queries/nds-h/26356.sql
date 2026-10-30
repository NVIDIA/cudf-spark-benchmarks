
SELECT 
    CONCAT('Part Name: ', p.p_name, ' - Manufacturer: ', p.p_mfgr, ' | Comment: ', p.p_comment) AS part_description,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    p.p_size > 10 AND 
    s.s_acctbal > 5000 
GROUP BY 
    p.p_partkey, r.r_name, n.n_name, s.s_name, p.p_name, p.p_mfgr, p.p_comment
ORDER BY 
    total_revenue DESC
LIMIT 10;
