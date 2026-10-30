SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    SUBSTRING(p.p_comment FROM 1 FOR 15) AS short_comment,
    CONCAT(c.c_name, ' - ', s.s_name) AS supplier_customer,
    COUNT(l.l_orderkey) AS total_orders,
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size > 20 AND 
    s.s_acctbal > 5000.00 AND 
    o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, c.c_name, s.s_name, p.p_comment
HAVING 
    COUNT(l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC;
