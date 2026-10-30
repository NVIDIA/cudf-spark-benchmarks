
SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    MIN(l.l_tax) AS min_tax,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN CHAR_LENGTH(p.p_name) > 30 THEN 'Long Name'
        ELSE 'Short Name'
    END AS name_length_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_retailprice > 50.00 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_quantity DESC;
