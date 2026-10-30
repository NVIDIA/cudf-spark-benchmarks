SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
    SUM(l.l_quantity) AS total_quantity_supplied,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, '(', CAST(p.p_size AS STRING), ') - ', p.p_comment), '; ') AS supplied_parts_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey AND l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name
ORDER BY 
    total_quantity_supplied DESC
LIMIT 10;