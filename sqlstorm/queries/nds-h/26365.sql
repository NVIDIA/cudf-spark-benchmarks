SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(s.s_acctbal) AS average_acct_balance, 
    CONCAT('Part: ', p.p_name, ', Total Suppliers: ', COUNT(DISTINCT ps.ps_suppkey), ', Avg. Account Balance: $', ROUND(AVG(s.s_acctbal), 2)) AS detailed_info
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100.00 
    AND s.s_comment LIKE '%reliable%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    average_acct_balance DESC
LIMIT 10;
