SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    p.p_brand AS part_brand,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS brand_rank,
    SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info
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
    p.p_retailprice > 100 
    AND s.s_acctbal < 5000
GROUP BY 
    s.s_name, p.p_name, p.p_brand, r.r_name, n.n_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 50
ORDER BY 
    brand_rank, total_available_quantity DESC;
