SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' sells the part ', p.p_name, 
           ' of type ', p.p_type, ' manufactured by ', p.p_mfgr) AS transaction_details,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_size > 10
GROUP BY 
    c.c_name, s.s_name, p.p_name, p.p_type, p.p_mfgr, r.r_name
ORDER BY 
    total_amount DESC
LIMIT 10;