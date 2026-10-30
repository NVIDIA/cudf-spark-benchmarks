SELECT 
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name, 
           ' - Comment: ', SUBSTRING(ps.ps_comment, 1, 30), '...') AS benchmark_string
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(s.s_name) > 5
    AND p.p_size BETWEEN 1 AND 50
    AND s.s_acctbal > 
        (SELECT AVG(s2.s_acctbal) 
         FROM supplier s2 
         WHERE s2.s_nationkey = s.s_nationkey)
ORDER BY 
    p.p_retailprice DESC
LIMIT 100;
