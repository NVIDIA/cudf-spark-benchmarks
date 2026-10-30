
SELECT 
    LOWER(CONCAT('Supplier ', s.s_name, ' from ', n.n_name)) AS supplier_info,
    UPPER(SUBSTRING(p.p_name, 1, 10)) AS short_part_name,
    REPLACE(p.p_comment, 'obsolete', 'updated') AS updated_comment,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE '%land%'
GROUP BY 
    s.s_name, n.n_name, p.p_name, p.p_comment
HAVING 
    AVG(ps.ps_supplycost) > 100.00
ORDER BY 
    order_count DESC, supplier_info;
