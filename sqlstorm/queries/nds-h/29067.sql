
SELECT 
    s.s_name AS supplier_name, 
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info, 
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied, 
    SUM(ps.ps_supplycost) AS total_supply_cost, 
    AVG(l.l_discount) AS average_discount_rate, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders 
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
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
    p.p_type LIKE '%metal%' 
    AND o.o_orderdate BETWEEN '1995-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, r.r_name, n.n_name 
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 10 
ORDER BY 
    total_supply_cost DESC, average_discount_rate ASC;
