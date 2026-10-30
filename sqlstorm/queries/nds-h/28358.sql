SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Quantity Available: ', ps.ps_availqty) AS supplier_part_info,
    SUBSTRING(p.p_comment FROM 1 FOR 20) AS truncated_comment,
    CASE 
        WHEN s.s_acctbal > 10000 THEN 'High Account Balance' 
        ELSE 'Standard Account Balance' 
    END AS acct_balance_category,
    LENGTH(s.s_address) AS address_length,
    REPLACE(s.s_comment, 'quality', 'standard') AS updated_comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    LENGTH(s.s_name) > 10 
    AND p.p_size BETWEEN 10 AND 20
ORDER BY 
    p.p_retailprice DESC
LIMIT 50;
