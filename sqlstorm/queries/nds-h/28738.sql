
WITH PartDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_mfgr,
           p.p_brand,
           SUBSTRING(p.p_comment FROM 1 FOR 20) AS short_comment,
           p.p_container,
           CONCAT(p.p_brand, ': ', p.p_name) AS branded_name,
           LENGTH(p.p_comment) AS comment_length
    FROM part p
),
SupplierDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           LEFT(s.s_comment, 50) AS short_supplier_comment,
           CASE
               WHEN s.s_acctbal > 1000 THEN 'High'
               WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'Low'
           END AS account_balance_cat
    FROM supplier s
),
NationDetails AS (
    SELECT n.n_nationkey,
           n.n_name,
           n.n_regionkey,
           INITCAP(n.n_comment) AS formatted_nation_comment
    FROM nation n
),
FinalResult AS (
    SELECT pd.p_partkey,
           pd.branded_name,
           sd.s_name,
           nd.n_name,
           pd.short_comment,
           sd.short_supplier_comment,
           pd.comment_length,
           sd.account_balance_cat
    FROM PartDetails pd
    JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
    WHERE pd.comment_length > 10
    ORDER BY pd.p_partkey, sd.s_name
)
SELECT * 
FROM FinalResult
LIMIT 100;
