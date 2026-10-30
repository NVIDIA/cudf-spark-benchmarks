
SELECT 
    CONCAT('Part Name: ', p.p_name, ', Retail Price: ', CAST(p.p_retailprice AS DECIMAL(10, 2)), 
    ', Supplier Name: ', s.s_name, ', Nation: ', n.n_name) AS summary_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
    )
    AND LENGTH(s.s_name) > 10
GROUP BY 
    p.p_name, p.p_retailprice, s.s_name, n.n_name
ORDER BY 
    n.n_name, p.p_name
LIMIT 100;
