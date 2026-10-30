
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(s.s_name, ' is a supplier located in nation with key ', s.s_nationkey) AS supplier_info,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
    )
),
TopNation AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY supplier_count DESC
    LIMIT 5
)
SELECT 
    pd.s_suppkey,
    pd.s_name,
    pd.s_nationkey,
    tn.n_name,
    pd.supplier_info,
    pd.comment_length
FROM SupplierDetails pd
JOIN TopNation tn ON pd.s_nationkey = tn.n_nationkey
ORDER BY pd.comment_length DESC;
