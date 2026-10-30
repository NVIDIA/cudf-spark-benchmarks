SELECT 
    p.p_partkey,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Supplier: ', s.s_name, ' from ', c.c_name, ' (', n.n_name, ')') AS supplier_info,
    REPLACE(p.p_comment, 'quality', 'excellence') AS updated_comment,
    (p.p_retailprice * ps.ps_availqty) AS total_value,
    CASE 
        WHEN p.p_size > 10 THEN 'Large'
        WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Small' 
    END AS size_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
WHERE 
    p.p_retailprice > 100.00
    AND n.n_name LIKE '%land%'
ORDER BY 
    total_value DESC
LIMIT 10;
