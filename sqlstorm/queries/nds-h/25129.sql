
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS number_of_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    CONCAT(n.n_name, '(', r.r_name, ')') AS nation_region
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    POSITION('special' IN p.p_comment) > 0 
AND 
    s.s_acctbal > 1000 
GROUP BY 
    s.s_name, n.n_name, r.r_name 
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5 
ORDER BY 
    total_available_quantity DESC, supplier_name;
