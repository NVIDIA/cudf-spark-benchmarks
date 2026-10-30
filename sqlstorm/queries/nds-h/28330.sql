SELECT 
    p.p_name,
    SUBSTRING(p.p_comment FROM 1 FOR 15) AS short_comment,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type,
    (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count,
    (SELECT AVG(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS avg_supply_cost,
    (SELECT COUNT(DISTINCT o.o_orderkey) FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE l.l_partkey = p.p_partkey) AS order_count
FROM 
    part p 
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_name ASC
LIMIT 10;
