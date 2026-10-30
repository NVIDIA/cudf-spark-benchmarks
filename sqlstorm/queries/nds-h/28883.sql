SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: $', CAST(p.p_retailprice AS CHAR(10)), ', Region: ', r.r_name) AS detailed_info,
    LENGTH(CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Price: $', CAST(p.p_retailprice AS CHAR(10)), ', Region: ', r.r_name)) AS info_length
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
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    info_length DESC
LIMIT 10;
