SELECT 
    SUBSTRING(p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s_nationkey) AS supplier_count,
    AVG(ps_supplycost) AS average_supply_cost,
    MAX(p_retailprice) AS max_price,
    MIN(CASE 
        WHEN p_type LIKE '%metal%' THEN p_size 
        ELSE NULL 
    END) AS min_metal_size,
    CONCAT(n_name, ' - ', r_name) AS nation_region
FROM 
    part 
JOIN 
    partsupp ON p_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
JOIN 
    nation ON s_nationkey = n_nationkey
JOIN 
    region ON n_regionkey = r_regionkey
WHERE 
    p_retailprice > 100
GROUP BY 
    short_name, nation_region
HAVING 
    COUNT(DISTINCT s_nationkey) > 1
ORDER BY 
    supplier_count DESC, max_price ASC;
