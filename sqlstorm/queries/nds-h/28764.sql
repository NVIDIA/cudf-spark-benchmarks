SELECT 
    CONCAT('Supplier: ', s_name, ' (', s_address, ') from Nation: ', n_name, ' has part: ', p_name, ' with price: $', CAST(ps_supplycost AS CHAR(10)), 
           ' and comment: ', ps_comment) AS detailed_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00 
    AND n.n_name LIKE 'A%'
ORDER BY 
    p.p_name ASC;
