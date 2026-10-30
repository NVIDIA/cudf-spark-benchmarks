
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(CASE WHEN RIGHT(p.p_name, 3) = 'con' THEN ps.ps_availqty ELSE 0 END) AS total_con_container_qty,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    r.r_name
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
    p.p_retailprice > 100
    AND s.s_acctbal < 5000
GROUP BY 
    p.p_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
ORDER BY 
    avg_supply_cost DESC, 
    supplier_count ASC;
