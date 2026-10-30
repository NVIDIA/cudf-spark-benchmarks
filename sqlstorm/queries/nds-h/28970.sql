SELECT 
    CONCAT('Supplier: ', s.s_name, ', Country: ', n.n_name, ', Products Supplied: ', 
        (SELECT COUNT(*) 
         FROM partsupp ps 
         WHERE ps.ps_suppkey = s.s_suppkey), 
    ' | Nation Comment: ', n.n_comment) AS supplier_info
FROM 
    supplier s 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
    AND n.n_name LIKE '%land%' 
ORDER BY 
    supplier_info DESC
LIMIT 10;
