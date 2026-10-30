SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    s.s_acctbal, 
    SUM(ps.ps_availqty) AS total_availqty, 
    SUM(ps.ps_supplycost) AS total_supplycost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    s.s_name, 
    s.s_acctbal
ORDER BY 
    total_availqty DESC
LIMIT 100;
