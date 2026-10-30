SELECT 
    p.p_name AS product_name, 
    s.s_name AS supplier_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(s.s_acctbal) AS average_supplier_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'Europe' 
    AND p.p_type LIKE '%metal%'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    SUM(ps.ps_availqty) > 10
ORDER BY 
    total_available_quantity DESC, average_supplier_balance ASC;
