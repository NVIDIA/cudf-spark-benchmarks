
SELECT 
    CONCAT('Supplier ', s.s_name, ' from ', n.n_name, ' supplies ', p.p_name, ' in ', r.r_name, ' region.') AS description,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 50.00 
    AND r.r_name LIKE 'Asia%'
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_available_quantity DESC;
