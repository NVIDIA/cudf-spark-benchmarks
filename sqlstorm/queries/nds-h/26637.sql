
SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(p.p_retailprice) AS average_retail_price, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(CASE 
        WHEN p.p_comment LIKE '%special%' THEN ps.ps_supplycost 
        ELSE 0 
    END) AS special_supply_costs
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size > 10) 
AND 
    p.p_name NOT LIKE '%ordinary%' 
GROUP BY 
    p.p_name, p.p_brand, p.p_type 
HAVING 
    SUM(ps.ps_availqty) > 100 
ORDER BY 
    average_retail_price DESC, supplier_count ASC;
