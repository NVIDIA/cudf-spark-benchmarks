
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MIN(LEFT(p.p_name, 10)) AS short_part_name,
    UPPER(CONCAT('Product: ', p.p_name)) AS formatted_product_name,
    CONCAT(SUBSTRING(p.p_comment, 1, 10), '...') AS short_comment,
    REPLACE(p.p_container, 'box', 'container') AS updated_container_type
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
    r.r_name LIKE '%Europe%'
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_comment, p.p_container
ORDER BY 
    total_available_quantity DESC, p.p_name ASC
LIMIT 50;
