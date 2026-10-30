SELECT 
    CONCAT_WS(' - ', s.s_name, s.s_address, s.s_phone) AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    MAX(p.p_retailprice) AS highest_price,
    MIN(p.p_retailprice) AS lowest_price,
    AVG(p.p_retailprice) AS average_price,
    SUM(p.p_retailprice) AS total_retail_value,
    MAX(p.p_size) AS largest_part_size,
    MIN(p.p_size) AS smallest_part_size,
    SUM(l.l_quantity) AS total_quantity_sold
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    s.s_comment LIKE '%excellent%'
    AND p.p_type LIKE 'part%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, s.s_phone
ORDER BY 
    total_quantity_sold DESC, supplier_info ASC
LIMIT 10;