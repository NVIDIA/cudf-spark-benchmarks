
SELECT
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier: ', s.s_name, ' supplies part: ', p.p_name, 
           ' with a retail price of: ', CAST(p.p_retailprice AS DECIMAL(10, 2)), 
           '. Comments: ', p.p_comment) AS full_description,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(l.l_shipdate) AS last_ship_date
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
WHERE
    s.s_comment LIKE '%quality%' AND 
    p.p_type LIKE '%metal%'
GROUP BY
    s.s_name, p.p_name, p.p_comment, p.p_retailprice
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_available_quantity DESC, last_ship_date DESC;
