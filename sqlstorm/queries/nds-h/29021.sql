SELECT 
    p.p_name,
    CONCAT('Manufactured by ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS product_details,
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND 
    l.l_shipdate < DATE '1998-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_address, p.p_mfgr, p.p_brand, p.p_type
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue_rank;