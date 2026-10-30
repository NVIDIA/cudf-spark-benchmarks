SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    p.p_brand, 
    p.p_type, 
    p.p_size, 
    p.p_container, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Region: ', r.r_name, ' - Nation: ', n.n_name) AS location_info
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
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND p.p_size > 10
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_comment, r.r_name, n.n_name
ORDER BY 
    avg_discounted_price DESC
LIMIT 50;