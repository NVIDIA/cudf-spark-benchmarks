SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN LENGTH(p.p_name) > 20 THEN ps.ps_availqty 
        ELSE 0 
    END) AS total_available_qty,
    ROUND(AVG(CASE 
        WHEN UPPER(p.p_brand) LIKE 'A%' THEN ps.ps_supplycost 
        ELSE NULL 
    END), 2) AS avg_supply_cost,
    MAX(LENGTH(p.p_comment)) AS max_comment_length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_type LIKE '%metal%'
    AND s.s_acctbal BETWEEN 1000 AND 10000
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY 
    total_available_qty DESC, 
    p.p_name;
