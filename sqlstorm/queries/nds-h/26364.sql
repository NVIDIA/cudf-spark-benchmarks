
SELECT 
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(CASE 
            WHEN POSITION('special' IN p.p_comment) > 0 THEN 1 
            ELSE 0 
        END) AS special_comments,
    SUBSTRING(MIN(p.p_name), 1, 10) AS min_part_name,
    AVG(CASE 
            WHEN p.p_size > 5 THEN p.p_retailprice 
            ELSE NULL 
        END) AS avg_price_large_parts,
    COUNT(DISTINCT CASE 
                      WHEN s.s_acctbal < 1000 AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%') 
                      THEN s.s_suppkey 
                   END) AS low_balance_suppliers_from_A
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 20.00 AND
    EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = s.s_nationkey AND n.n_comment LIKE '%high quality%')
GROUP BY 
    p.p_brand, p.p_name, p.p_size, p.p_retailprice, s.s_acctbal, s.s_nationkey
ORDER BY 
    unique_parts DESC;
