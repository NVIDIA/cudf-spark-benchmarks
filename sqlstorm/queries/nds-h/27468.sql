
SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_info,
    UPPER(p.p_type) AS upper_type,
    LOWER(p.p_comment) AS lower_comment,
    LENGTH(p.p_name) AS name_length,
    CHAR_LENGTH(s.s_address) AS address_length,
    SUBSTRING(s.s_phone, 1, 3) AS phone_prefix,
    REPLACE(p.p_comment, 'nice', 'excellent') AS adjusted_comment,
    TRIM(p.p_container) AS trimmed_container
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
    p.p_retailprice > 100.00
    AND s.s_acctbal BETWEEN 5000 AND 10000
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_type, p.p_comment, p.p_container, s.s_address, s.s_phone
ORDER BY 
    name_length DESC, upper_type ASC
LIMIT 50;
