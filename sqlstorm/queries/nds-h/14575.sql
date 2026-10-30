
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    s.s_acctbal AS supplier_balance, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, s.s_acctbal
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_sales DESC;
