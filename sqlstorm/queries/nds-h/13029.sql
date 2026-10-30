SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_retailprice, 
    s.s_name, 
    s.s_acctbal, 
    SUM(l.l_quantity) AS total_quantity_sold
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, s.s_name, s.s_acctbal
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
