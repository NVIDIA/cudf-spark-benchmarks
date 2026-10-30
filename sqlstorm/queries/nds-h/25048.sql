
SELECT 
    SUBSTRING(p.p_name, 1, 20) AS short_name,
    CONCAT('Manufactured by ', p.p_mfgr) AS mfgr_description,
    REPLACE(p.p_comment, 'nice', 'pleasant') AS updated_comment,
    CASE 
        WHEN p.p_size > 10 THEN 'Large'
        WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Small' 
    END AS size_category,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    p.p_name, p.p_mfgr, p.p_comment, p.p_size
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    size_category DESC, max_supply_cost DESC;
