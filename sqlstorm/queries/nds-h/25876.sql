
SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(ps.ps_supplycost) AS average_supply_cost, 
    MAX(CASE WHEN p.p_comment LIKE '%urgent%' THEN p.p_retailprice ELSE NULL END) AS max_retail_price_urgent_parts,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    CONCAT(SUBSTRING(s.s_address FROM 1 FOR 20), '...', SUBSTRING(s.s_address FROM LENGTH(s.s_address) - 9 FOR 10)) AS short_address,
    REPLACE(p.p_comment, 'supply', 'service') AS updated_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 100.00 AND
    s.s_acctbal > 0 AND
    (o.o_orderstatus IN ('O', 'F') OR o.o_orderstatus IS NULL)
GROUP BY 
    s.s_name, p.p_name, s.s_address, p.p_comment
ORDER BY 
    total_available_quantity DESC, 
    average_supply_cost ASC
LIMIT 50;
