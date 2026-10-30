SELECT 
    p.p_partkey,
    p.p_name,
    s.s_suppkey,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_suppkey, s.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
