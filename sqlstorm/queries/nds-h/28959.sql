
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    MAX(CHAR_LENGTH(p.p_comment)) AS max_comment_length,
    CONCAT('Total:', SUM(l.l_extendedprice + l.l_discount - (l.l_extendedprice * l.l_discount / 100))) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND LOWER(p.p_mfgr) LIKE '%eco%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_quantity DESC
LIMIT 10;
