
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name, ', Region: ', r.r_name) AS supplier_info, 
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
    MAX(ps.ps_comment) AS longest_comment
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    s.s_suppkey, s.s_name, n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
