
SELECT 
    p.p_partkey, 
    SUBSTRING(p.p_name, 1, 10) AS short_name, 
    CONCAT('Manufacturer: ', p.p_mfgr) AS mfgr_info, 
    REPLACE(p.p_comment, 'old', 'new') AS updated_comment, 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    s.s_name AS supplier_name, 
    c.c_name AS customer_name, 
    o.o_orderkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size > 25 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_comment, r.r_name, n.n_name, s.s_name, c.c_name, o.o_orderkey
ORDER BY 
    total_revenue DESC
LIMIT 10;
