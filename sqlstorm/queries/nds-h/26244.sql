
WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container, 
           p.p_retailprice, p.p_comment, 
           SUBSTRING(p.p_comment FROM POSITION('green' IN p.p_comment) + LENGTH('green')) AS comment_after_green,
           REPLACE(p.p_name, 'special', 'premium') AS formatted_name
    FROM part p
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           COUNT(l.l_orderkey) AS total_lineitems,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice
)
SELECT si.nation_name, pi.formatted_name, os.o_orderstatus, os.total_lineitems, os.net_amount
FROM SupplierInfo si
JOIN PartInfo pi ON pi.p_container LIKE '%box%'
JOIN OrderSummary os ON os.total_lineitems > 5
ORDER BY os.net_amount DESC, si.s_acctbal DESC
LIMIT 10;
