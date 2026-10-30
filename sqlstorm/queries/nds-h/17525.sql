SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    p.p_name
ORDER BY 
    total_quantity DESC
LIMIT 10;
