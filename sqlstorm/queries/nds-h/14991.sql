SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(s.s_acctbal) AS avg_acctbal
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, s.s_name
ORDER BY 
    total_availqty DESC
LIMIT 100;
