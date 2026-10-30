SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Address: ', s.s_address, ' | Nation: ', n.n_name) AS supplier_info,
    SUBSTRING(p.p_name, 1, 20) AS short_part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS average_price,
    MAX(l.l_discount) AS max_discount,
    l.l_shipmode AS shipping_method
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size > 12
AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    supplier_info, short_part_name, l.l_shipmode
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, average_price ASC;