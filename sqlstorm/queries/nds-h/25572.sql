WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        LENGTH(p.p_name) AS name_length,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        LENGTH(s.s_name) AS supplier_name_length,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal >= 50000
),
AggregateInfo AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.short_comment,
        pd.name_length,
        sd.s_name,
        sd.supplier_name_length,
        pd.p_retailprice * sd.s_acctbal AS value_metric
    FROM 
        PartDetails pd
    JOIN 
        SupplierDetails sd ON pd.p_partkey % sd.s_suppkey = 0 
)
SELECT 
    a.p_partkey,
    a.p_name,
    a.short_comment,
    a.name_length,
    a.s_name,
    a.supplier_name_length,
    a.value_metric
FROM 
    AggregateInfo a
WHERE 
    a.value_metric > 1000000
ORDER BY 
    a.value_metric DESC
LIMIT 10;
