
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    s.s_name AS supplier_name,
    REPLACE(INITCAP(n.n_name), ' ', '-') AS nation_hyphenated,
    CONCAT(UPPER(s.s_phone), ' (', LENGTH(s.s_phone), ' chars)') AS formatted_phone,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 1000
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    p.p_name,
    short_comment,
    supplier_name,
    nation_hyphenated,
    formatted_phone
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    avg_extended_price DESC
LIMIT 10;
