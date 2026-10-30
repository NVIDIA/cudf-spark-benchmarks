SELECT 
    CONCAT(s.s_name, ' (', s.s_suppkey, ')') AS supplier_info,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(l.l_quantity) AS total_quantity_sold,
    RANK() OVER (ORDER BY SUM(l.l_quantity) DESC) AS rank_by_quantity
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%preferred%' 
    AND o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_suppkey, s.s_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;