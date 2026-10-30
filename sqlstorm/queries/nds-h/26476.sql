WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type) AS part_details,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' from ', s.s_address, ', ', n.n_name) AS supplier_info,
        s.s_acctbal * (SELECT AVG(s_acctbal) FROM supplier) AS account_balance_ratio
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
Benchmarking AS (
    SELECT 
        pd.p_partkey,
        pd.part_details,
        sd.supplier_info,
        pd.comment_length,
        sd.account_balance_ratio
    FROM PartDetails pd
    JOIN SupplierDetails sd ON pd.p_partkey % 100 = sd.s_suppkey % 100
)
SELECT 
    part_details,
    supplier_info,
    AVG(comment_length) AS avg_comment_length,
    AVG(account_balance_ratio) AS avg_account_balance_ratio
FROM Benchmarking
GROUP BY part_details, supplier_info
ORDER BY avg_comment_length DESC, avg_account_balance_ratio DESC
LIMIT 10;
