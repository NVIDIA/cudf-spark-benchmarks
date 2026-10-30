SELECT 
    CONCAT(SUBSTRING(p.p_name, 1, 10), '...') AS truncated_part_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    r.r_name AS region_name,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE 0 
        END) AS total_returned_quantity
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%quality%'
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    r.r_name, truncated_part_name
ORDER BY 
    total_orders DESC, average_supply_cost ASC
LIMIT 10;