
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MIN(SUBSTRING(p.p_comment, 1, 10)) AS short_comment,
    MAX(LENGTH(p.p_comment)) AS max_comment_length,
    AVG(s.s_acctbal) AS average_supplier_account_balance
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
    r.r_name LIKE 'Asia%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    average_supplier_account_balance DESC
LIMIT 10;
