
SELECT 
    p.p_name AS part_name,
    p.p_mfgr AS manufacturer,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CONCAT(n.n_name, ' - ', r.r_name) AS nation_region
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
    p.p_size > 10 AND 
    o.o_orderstatus = 'O' AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_mfgr, p.p_comment, n.n_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_revenue DESC, total_quantity DESC;
