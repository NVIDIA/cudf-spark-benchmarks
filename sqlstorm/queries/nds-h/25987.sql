
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    CONCAT('Supplier ', s.s_name, ' provides ', p.p_name, ' with a price of $', ROUND(ps.ps_supplycost, 2)) AS description,
    CASE 
        WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
        WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
        WHEN p.p_size > 20 THEN 'Large'
    END AS size_category,
    COUNT(ps.ps_partkey) AS supply_count,
    SUM(ps.ps_availqty) AS total_avail_qty
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_comment LIKE '%reliable%'
GROUP BY 
    s.s_name, p.p_name, ps.ps_supplycost, p.p_size
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_avail_qty DESC,
    supplier_name ASC;
