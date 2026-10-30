
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
    MAX(p.p_retailprice) AS highest_retail_price
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_name LIKE '%rubber%'
    AND s.s_comment NOT LIKE '%urgent%'
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC
LIMIT 10;
