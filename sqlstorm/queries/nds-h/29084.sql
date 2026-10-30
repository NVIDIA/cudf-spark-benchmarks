
WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        ROUND(p.p_retailprice, 2) AS p_retailprice, 
        SUBSTRING(p.p_comment, 1, 20) AS p_comment_short
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        CONCAT(s.s_address, ' (', s.s_phone, ')') AS s_contact_info, 
        ROUND(s.s_acctbal, 2) AS s_acctbal, 
        CHAR_LENGTH(s.s_comment) AS s_comment_length
    FROM 
        supplier s
)
SELECT 
    pd.p_partkey, 
    pd.p_name, 
    pd.p_mfgr, 
    pd.p_brand, 
    pd.p_type, 
    sd.s_suppkey, 
    sd.s_name, 
    sd.s_contact_info, 
    pd.p_retailprice, 
    pd.p_comment_short, 
    sd.s_comment_length
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    pd.p_size BETWEEN 10 AND 20 
    AND sd.s_acctbal > 1000.00
ORDER BY 
    pd.p_name ASC, 
    sd.s_name DESC
LIMIT 100;
