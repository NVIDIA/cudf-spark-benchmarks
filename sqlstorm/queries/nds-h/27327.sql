WITH PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_retailprice, 
           p.p_comment, 
           SUBSTRING(p.p_name, 1, 10) AS short_name,
           LENGTH(p.p_comment) AS comment_length
    FROM part p
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           s.s_phone, 
           s.s_acctbal, 
           LENGTH(s.s_comment) AS comment_length,
           CASE 
               WHEN s.s_acctbal > 50000 THEN 'High'
               WHEN s.s_acctbal BETWEEN 20000 AND 50000 THEN 'Medium'
               ELSE 'Low'
           END AS acctbal_category
    FROM supplier s
),
CustomerInfo AS (
    SELECT c.c_custkey, 
           c.c_name, 
           c.c_mktsegment,
           CONCAT(c.c_name, ' - ', c.c_mktsegment) AS full_description
    FROM customer c
),
OrderStats AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           SUM(l.l_extendedprice) AS total_order_value,
           COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT pd.short_name, 
       pd.p_mfgr, 
       pd.p_brand, 
       pd.p_retailprice,
       sd.s_name AS supplier_name,
       ci.full_description AS customer_details,
       os.total_order_value,
       os.lineitem_count,
       pd.comment_length AS part_comment_length,
       sd.comment_length AS supplier_comment_length,
       sd.acctbal_category
FROM PartDetails pd
JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN OrderStats os ON ps.ps_partkey = os.o_orderkey
JOIN CustomerInfo ci ON os.o_orderkey = ci.c_custkey
WHERE pd.p_type LIKE '%screws%'
ORDER BY os.total_order_value DESC
LIMIT 10;