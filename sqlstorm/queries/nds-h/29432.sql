SELECT 
    p.p_name AS part_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_balance,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Available: ', CAST(SUM(ps.ps_availqty) AS STRING), ', Suppliers: ', CAST(COUNT(DISTINCT s.s_suppkey) AS STRING)) AS availability_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name LIKE '%United%'
    AND p.p_retailprice > 50.00
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC;
