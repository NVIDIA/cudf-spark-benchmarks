SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Part:', p.p_partkey, ' | Name:', p.p_name) AS part_info,
    CASE 
        WHEN LENGTH(p.p_name) >= 10 THEN 'Long Name' 
        ELSE 'Short Name' 
    END AS name_length_category,
    MAX(CASE WHEN n.n_name = 'UNITED STATES' THEN s.s_acctbal ELSE NULL END) AS max_us_supplier_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size IN (10, 20, 30)
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
