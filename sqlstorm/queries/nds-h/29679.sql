WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment,
           REPLACE(s.s_name, 'Supplier', 'Provider') AS modified_name,
           CONCAT('Contact: ', s.s_name, '; Phone: ', s.s_phone) AS contact_info
    FROM supplier s
    WHERE s.s_acctbal > 10000
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM SupplierDetails s)
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_size,
           CASE 
               WHEN p.p_retailprice < 50 THEN 'Cheap'
               WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Affordable'
               ELSE 'Expensive'
           END AS price_category
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT s.s_suppkey FROM SupplierDetails s)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderpriority,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_items_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderpriority
)
SELECT sd.s_name, nd.n_name, pd.p_name, os.o_orderkey, os.total_line_items_value,
       CASE 
           WHEN os.total_line_items_value > 50000 THEN 'High Value'
           ELSE 'Regular Value'
       END AS order_value_category
FROM SupplierDetails sd
JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
JOIN PartDetails pd ON pd.p_partkey = sd.s_suppkey
JOIN OrderSummary os ON os.o_orderkey = sd.s_suppkey
ORDER BY os.total_line_items_value DESC, sd.modified_name;
