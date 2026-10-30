
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
SupplierStats AS (
    SELECT r.r_name AS region_name, COUNT(DISTINCT s.s_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal, AVG(s.s_acctbal) AS avg_acctbal
    FROM region r
    LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY r.r_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           CASE WHEN o.o_orderstatus = 'O' THEN 'Open'
                WHEN o.o_orderstatus = 'F' THEN 'Finished'
                ELSE 'Other' END AS order_status,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_totalprice > 1000 AND o.o_orderdate >= '1997-01-01'
),
LineItemMetrics AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT COALESCE(ss.region_name, 'Unknown Region') AS region_name,
       l_metrics.net_revenue,
       ss.total_acctbal AS total_supplier_acctbal,
       hvo.order_status, hvo.o_orderkey,
       CASE WHEN hvo.price_rank <= 5 THEN 'Top 5 Orders' ELSE 'Other Orders' END AS order_ranking
FROM SupplierStats ss
FULL OUTER JOIN LineItemMetrics l_metrics ON ss.nation_count > 5
LEFT JOIN HighValueOrders hvo ON l_metrics.l_orderkey = hvo.o_orderkey
WHERE (ss.total_acctbal > 10000 OR l_metrics.return_count > 2)
  AND (hvo.o_orderkey IS NOT NULL OR l_metrics.net_revenue IS NULL) 
ORDER BY ss.region_name, l_metrics.net_revenue DESC;
