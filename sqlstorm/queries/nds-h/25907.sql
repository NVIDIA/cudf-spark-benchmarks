SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT('Supplier: ', s.s_name, ' providing Part: ', p.p_name, ' has a total quantity of ', SUM(l.l_quantity), ' and an average supply cost of ', AVG(ps.ps_supplycost)) AS detailed_info
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
WHERE 
    p.p_retailprice > 50.00 
    AND l.l_shipdate > '1997-01-01'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_quantity DESC, avg_supply_cost ASC
LIMIT 10;