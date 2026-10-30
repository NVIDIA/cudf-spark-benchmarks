
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    CONCAT('Part: ', p.p_name, ', supplied by: ', s.s_name, ' from nation: ', n.n_name, ', with retail price: $', CAST(ROUND(p.p_retailprice, 2) AS STRING)) AS detailed_info,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    REPLACE(LOWER(p.p_type), ' ', '_') AS type_slug
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey,
    p.p_name,
    s.s_name,
    n.n_name,
    p.p_retailprice,
    p.p_comment,
    p.p_type
ORDER BY 
    p.p_retailprice DESC
LIMIT 10;
