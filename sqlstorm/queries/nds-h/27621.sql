WITH PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container, 
           p.p_retailprice, 
           p.p_comment,
           SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM part p
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           n.n_name AS nation_name, 
           s.s_phone, 
           s.s_acctbal, 
           s.s_comment,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT pd.p_name, 
       pd.p_brand, 
       pd.p_type, 
       sd.s_name, 
       sd.nation_name, 
       os.total_revenue, 
       sd.comment_length, 
       pd.short_comment
FROM PartDetails pd
JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN OrderSummary os ON os.o_orderkey = ps.ps_suppkey
WHERE pd.p_size > 10 
AND os.total_revenue > 10000
ORDER BY os.total_revenue DESC, sd.comment_length ASC
LIMIT 50;
