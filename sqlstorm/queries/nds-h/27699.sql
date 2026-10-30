SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers_ordered,
    r.r_name AS region_name,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Demand'
        WHEN COUNT(DISTINCT o.o_orderkey) BETWEEN 5 AND 10 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, r.r_name
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;