SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_discount) AS total_discount,
    TRIM(UPPER(p.p_brand)) AS processed_brand,
    LEFT(p.p_comment, 15) AS short_comment,
    CONCAT('Part: ', p.p_name, ' | Avg Cost: ', ROUND(AVG(ps.ps_supplycost), 2)) AS detail_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_type LIKE '%widget%'
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
GROUP BY 
    p.p_name, processed_brand, short_comment
HAVING 
    AVG(ps.ps_supplycost) > 50.00
ORDER BY 
    supplier_count DESC, total_discount DESC
LIMIT 10;