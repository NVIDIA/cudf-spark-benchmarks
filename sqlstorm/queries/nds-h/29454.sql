
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS average_balance,
    r.r_name AS region_name,
    CONCAT('Details: ', p.p_name, ' | ', s.s_name) AS detail_info
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
    p.p_retailprice > 50.00 AND
    s.s_acctbal < (SELECT AVG(s1.s_acctbal) FROM supplier s1)
GROUP BY 
    p.p_name, p.p_comment, r.r_name, s.s_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    average_balance DESC, p.p_name;
