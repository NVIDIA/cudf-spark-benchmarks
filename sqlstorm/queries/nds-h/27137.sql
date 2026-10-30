
SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    CONCAT(n.n_name, ' - ', r.r_name) AS region_description
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY 
    p.p_name, p.p_comment, n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
