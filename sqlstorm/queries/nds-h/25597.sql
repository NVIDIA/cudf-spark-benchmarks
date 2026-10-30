
SELECT 
    COUNT(*) AS total_parts,
    AVG(p.p_retailprice) AS average_price,
    MAX(LENGTH(REPLACE(p.p_comment, ' ', ''))) AS max_comment_length,
    MIN(LENGTH(REPLACE(p.p_comment, ' ', ''))) AS min_comment_length,
    SUBSTRING(p.p_name, 1, 10) AS sample_part_name,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_size BETWEEN 10 AND 30
    AND n.n_name LIKE 'A%'
    AND s.s_acctbal > (SELECT AVG(s_inner.s_acctbal) FROM supplier s_inner WHERE s_inner.s_comment LIKE '%reliable%')
GROUP BY 
    r.r_name, n.n_name, p.p_retailprice, p.p_comment, p.p_name
ORDER BY 
    total_parts DESC, average_price ASC;
