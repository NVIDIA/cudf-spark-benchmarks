SELECT 
    CONCAT('Part: ', p_name, ' | Supplier: ', s_name, ' | Nation: ', n_name) AS details,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(ps_supplycost) AS average_supply_cost,
    MAX(p_retailprice) AS max_retail_price,
    MIN(p_retailprice) AS min_retail_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%comp%' 
    AND n.n_name IN ('USA', 'Germany', 'France')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name
HAVING 
    SUM(ps_availqty) > 50
ORDER BY 
    details ASC;
