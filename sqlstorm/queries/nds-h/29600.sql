WITH StringProcessed AS (
    SELECT DISTINCT 
        CONCAT(p_name, ' - ', p_mfgr, ' - ', p_brand) AS full_description,
        LENGTH(CONCAT(p_name, ' - ', p_mfgr, ' - ', p_brand)) AS desc_length,
        SUBSTRING(p_comment, 1, 10) AS short_comment
    FROM part
    WHERE p_size BETWEEN 1 AND 25
),
NationFiltered AS (
    SELECT 
        n_name,
        LENGTH(n_name) AS nation_name_length
    FROM nation
    WHERE n_comment LIKE '%industry%'
),
SupplierDetails AS (
    SELECT 
        s_name,
        s_acctbal,
        (CASE 
            WHEN s_acctbal > 5000 THEN 'High Value' 
            ELSE 'Low Value' 
         END) AS account_classification
    FROM supplier
    WHERE s_comment NOT LIKE '%damaged%'
),
CombinedData AS (
    SELECT 
        sp.full_description,
        nf.n_name,
        sf.s_name,
        sf.account_classification,
        sp.desc_length,
        nf.nation_name_length
    FROM StringProcessed sp
    JOIN NationFiltered nf ON nf.nation_name_length > 5
    JOIN SupplierDetails sf ON sf.s_acctbal BETWEEN 1000 AND 10000
)
SELECT 
    full_description,
    n_name,
    s_name,
    account_classification,
    desc_length,
    (SELECT COUNT(*) FROM lineitem) AS total_lineitems
FROM CombinedData
ORDER BY desc_length DESC, n_name ASC;
