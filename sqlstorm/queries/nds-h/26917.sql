SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_address, ', ', s.s_phone), '; ') AS supplier_details,
    MAX(CASE WHEN l.l_shipmode = 'AIR' THEN l.l_extendedprice ELSE 0 END) AS max_air_extended_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
WHERE 
    p.p_comment LIKE '%special%' AND
    p.p_brand = 'Brand#10'
GROUP BY 
    p.p_name
ORDER BY 
    total_available_qty DESC
LIMIT 10;
