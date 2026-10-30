
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_qty, 
    MAX(CASE WHEN s.s_acctbal > 1000 THEN 'High Balance' ELSE 'Low Balance' END) AS supplier_balance_status,
    LEFT(p.p_comment, 10) AS short_comment,
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 50
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_qty DESC, supplier_part_info
LIMIT 20;
