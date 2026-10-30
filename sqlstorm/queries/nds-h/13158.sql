SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem AS l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
ORDER BY 
    revenue DESC
LIMIT 10;
