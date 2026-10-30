
SELECT 
    p.p_brand, 
    p.p_type, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    MAX(ps.ps_comment) AS longest_supply_comment,
    REPLACE(UPPER(p.p_name), ' ', '-') AS modified_product_name
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
WHERE 
    r.r_name = 'ASIA' AND 
    p.p_size BETWEEN 10 AND 20 AND 
    p.p_retailprice > 50.00
GROUP BY 
    p.p_brand, 
    p.p_type, 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_acctbal) > 5
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
