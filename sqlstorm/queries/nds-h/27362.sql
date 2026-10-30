
SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(LENGTH(SUBSTRING(s.s_name, POSITION(' ' IN s.s_name) + 1, LENGTH(s.s_name)))) AS avg_length_supplier_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    MAX(l.l_extendedprice) AS max_price,
    region.r_name AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region ON n.n_regionkey = region.r_regionkey
WHERE 
    p.p_retailprice > 20.00
GROUP BY 
    p.p_name, region.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_quantity DESC, avg_length_supplier_name ASC
LIMIT 100;
