WITH FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand,
        TRIM(p.p_type) AS trimmed_type,
        UPPER(p.p_comment) AS upper_comment
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
        AND p.p_retailprice > 50.00
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        TRIM(s.s_comment) AS trimmed_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE 'USA%'
) 
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_brand, 
    fp.trimmed_type, 
    sd.s_name, 
    sd.s_address, 
    LENGTH(sd.trimmed_comment) AS comment_length, 
    COUNT(li.l_orderkey) AS order_count
FROM 
    FilteredParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
GROUP BY 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_brand, 
    fp.trimmed_type, 
    sd.s_name, 
    sd.s_address, 
    sd.trimmed_comment
HAVING 
    COUNT(li.l_orderkey) > 0
ORDER BY 
    fp.p_brand, 
    comment_length DESC;
