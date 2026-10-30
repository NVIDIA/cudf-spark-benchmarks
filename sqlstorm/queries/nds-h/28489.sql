SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    CONCAT('Product: ', p.p_name, ', Suppliers: ', COUNT(DISTINCT ps.ps_suppkey), ', Average Price: $', ROUND(AVG(p.p_retailprice), 2)) AS detailed_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_name IN (SELECT n2.n_name FROM nation n2 WHERE n2.n_regionkey=(SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5 AND 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    avg_retail_price DESC;
