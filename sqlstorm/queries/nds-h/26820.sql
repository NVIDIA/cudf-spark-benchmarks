
SELECT 
    CONCAT(s.s_name, ' (', s.s_nationkey, ')') AS supplier_info,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS last_ship_date,
    REPLACE(p.p_name, ' ', '_') AS formatted_part_name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND s.s_comment IS NOT NULL
GROUP BY 
    s.s_name, s.s_nationkey, p.p_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC, last_ship_date DESC
LIMIT 10;
