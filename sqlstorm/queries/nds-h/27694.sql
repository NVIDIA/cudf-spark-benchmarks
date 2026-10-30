SELECT 
    CONCAT('Supplier: ', s_name, ' | Address: ', s_address, ' | Part: ', p_name, ' | Cost: $', CAST(ps_supplycost AS CHAR(12)), ' | Comment: ', ps_comment) AS detailed_info
FROM 
    supplier AS s
JOIN 
    partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part AS p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_acctbal > 1000.00
AND 
    p.p_retailprice < 500.00
ORDER BY 
    p.p_name, s.s_name;
