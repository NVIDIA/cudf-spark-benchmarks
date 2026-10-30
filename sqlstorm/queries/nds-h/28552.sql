WITH DetailedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        CONCAT(p.p_name, ' ', p.p_mfgr) AS product_info,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        TRIM(s.s_comment) AS supplier_comment,
        REPLACE(s.s_name, 'Supplier', 'Provider') AS provider_name
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
),
CombinedInfo AS (
    SELECT 
        dp.p_partkey,
        dp.product_info,
        dp.cleaned_comment,
        sd.s_name,
        sd.provider_name
    FROM 
        DetailedParts dp
    JOIN 
        partsupp ps ON dp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    ci.product_info,
    ci.cleaned_comment,
    ci.s_name,
    ci.provider_name,
    COUNT(*) AS supply_count
FROM 
    CombinedInfo ci
GROUP BY 
    ci.product_info, 
    ci.cleaned_comment, 
    ci.s_name, 
    ci.provider_name
HAVING 
    COUNT(*) > 1
ORDER BY 
    supply_count DESC;
