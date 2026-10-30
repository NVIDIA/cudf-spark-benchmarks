
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(ls.l_shipdate) AS last_ship_date,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'High Price'
        WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Medium Price'
        ELSE 'Low Price'
    END AS price_category
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    lineitem ls ON ps.ps_partkey = ls.l_partkey 
WHERE 
    s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment, p.p_retailprice, comment_length, price_category
ORDER BY 
    price_category, comment_length DESC
LIMIT 50;
