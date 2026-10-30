SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(CASE WHEN LENGTH(p.p_comment) > 10 THEN 1 ELSE 0 END) AS long_comments,
    SUBSTRING(p.p_brand FROM 1 FOR 4) AS brand_prefix,
    CONCAT('Count: ', CAST(COUNT(DISTINCT ps.ps_partkey) AS STRING), ' | Unique Suppliers: ', CAST(COUNT(DISTINCT ps.ps_suppkey) AS STRING)) AS summary
FROM
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 100
    AND UPPER(s.s_name) LIKE 'A%'
    AND EXISTS (
        SELECT 1 
        FROM customer c 
        JOIN orders o ON c.c_custkey = o.o_custkey 
        WHERE o.o_totalprice > 500 
        AND c.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'USA'
        )
    )
GROUP BY 
    p.p_name, 
    p.p_brand
HAVING 
    COUNT(ps.ps_partkey) > 5
ORDER BY 
    unique_suppliers DESC, 
    p.p_name;
