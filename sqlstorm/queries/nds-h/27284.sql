SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    SUM(l.l_quantity) AS total_quantity_sold,
    MAX(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS highest_fully_paid_order,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
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
    p.p_comment LIKE '%premium%' 
    AND l.l_shipmode IN ('AIR', 'TRUCK')
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, r.r_name, n.n_name
HAVING 
    AVG(ps.ps_supplycost) > 100.00
ORDER BY 
    total_quantity_sold DESC, supplier_count ASC;