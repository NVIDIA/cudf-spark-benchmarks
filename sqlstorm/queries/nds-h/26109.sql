
SELECT 
    CONCAT('Supplier Name: ', s.s_name, ' | Nation: ', n.n_name, ' | Total Cost: ', SUM(ps.ps_supplycost * ps.ps_availqty), 
           ' | Part Count: ', COUNT(DISTINCT ps.ps_partkey)) AS supplier_summary,
    s.s_name,
    n.n_name
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 5000 
    AND p.p_type LIKE '%metal%'
    AND (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
GROUP BY 
    s.s_name, n.n_name
ORDER BY 
    SUM(ps.ps_supplycost * ps.ps_availqty) DESC, supplier_summary;
