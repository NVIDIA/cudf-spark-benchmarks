SELECT 
    p.p_name,
    s.s_name,
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS detailed_info,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    p.p_retailprice * ps.ps_availqty AS total_value,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 15 AND 50 
    AND s.s_acctbal > 1000
    AND POSITION('fragile' IN p.p_comment) > 0
ORDER BY 
    total_value DESC, 
    comment_length ASC
LIMIT 10;
