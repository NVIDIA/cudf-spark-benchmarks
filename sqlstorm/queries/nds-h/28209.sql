SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(s.s_acctbal) AS min_supplier_acctbal,
    CONCAT('Part: ', p.p_name, ', Suppliers: ', COUNT(DISTINCT ps.ps_suppkey), ', Total Quantity: ', SUM(l.l_quantity), ', Avg Price: ', AVG(l.l_extendedprice), ', Max Discount: ', MAX(l.l_discount), ', Min Supplier Account Balance: ', MIN(s.s_acctbal)) AS benchmark_string
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 10
ORDER BY 
    total_quantity DESC
LIMIT 50;
