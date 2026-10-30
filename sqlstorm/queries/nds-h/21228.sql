
WITH total_supplier_cost AS (
    SELECT ps_suppkey, SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM partsupp
    GROUP BY ps_suppkey
),
high_value_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
lineitem_analysis AS (
    SELECT l.l_suppkey, 
           COUNT(l.l_orderkey) AS order_count, 
           AVG(l.l_extendedprice) AS avg_price, 
           SUM(CASE WHEN l.l_discount BETWEEN 0.05 AND 0.07 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discount_sales
    FROM lineitem l
    GROUP BY l.l_suppkey
),
final_data AS (
    SELECT ns.n_name,
           COALESCE(hvs.s_name, 'Unknown Supplier') AS supplier_name,
           COALESCE(ts.total_cost, 0) AS supplier_total_cost,
           la.order_count,
           la.avg_price,
           la.discount_sales
    FROM nation_stats ns
    LEFT JOIN high_value_suppliers hvs ON ns.supplier_count < 5
    LEFT JOIN total_supplier_cost ts ON hvs.s_suppkey = ts.ps_suppkey
    LEFT JOIN lineitem_analysis la ON hvs.s_suppkey = la.l_suppkey
)
SELECT f.n_name, f.supplier_name, f.supplier_total_cost, f.order_count, f.avg_price, f.discount_sales
FROM final_data f
WHERE f.supplier_total_cost IS NOT NULL
  AND (f.order_count IS NOT NULL OR f.supplier_name LIKE '%Inc%')
  AND f.discount_sales > 100.00
ORDER BY f.supplier_total_cost DESC, f.order_count DESC
LIMIT 10;
