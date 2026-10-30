WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        LOWER(p.p_comment) AS lower_comment
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        TRIM(s.s_address) AS trimmed_address
    FROM 
        supplier s
),
CombinedDetails AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_mfgr,
        sd.s_name,
        sd.short_comment,
        pd.comment_length,
        CONCAT('Part: ', pd.p_name, ' | Supplier: ', sd.s_name, ' | Comment length: ', pd.comment_length) AS combined_info
    FROM 
        PartDetails pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    cd.combined_info
FROM 
    CombinedDetails cd
WHERE 
    cd.comment_length > 20
ORDER BY 
    cd.comment_length DESC
LIMIT 10;
