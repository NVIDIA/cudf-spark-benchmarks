WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
NationalSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT sd.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, SUM(l.l_discount) AS total_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
    HAVING SUM(l.l_discount) > 0.2 * o.o_totalprice
),
FinalResults AS (
    SELECT ns.n_name,
           COALESCE(SUM(hvo.o_totalprice), 0) AS total_high_value_orders,
           MAX(sd.s_acctbal) AS max_supplier_acctbal
    FROM NationalSupplier ns
    LEFT JOIN HighValueOrders hvo ON ns.supplier_count > 0
    LEFT JOIN SupplierDetails sd ON ns.n_nationkey = sd.s_suppkey
    GROUP BY ns.n_name
)
SELECT *,
       CASE 
           WHEN total_high_value_orders = 0 THEN 'No High Value Orders'
           WHEN max_supplier_acctbal IS NULL THEN 'No Supplier Data Available' 
           ELSE 'Data Available'
       END AS status
FROM FinalResults
WHERE max_supplier_acctbal < (SELECT AVG(s_acctbal) FROM supplier) OR total_high_value_orders > 10000
ORDER BY n_name;
