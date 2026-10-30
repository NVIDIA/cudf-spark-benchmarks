
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
), LargestOrders AS (
    SELECT ro.o_orderkey, ro.o_custkey, ro.o_orderstatus, ro.o_totalprice
    FROM RankedOrders ro
    WHERE ro.price_rank <= 5
)
SELECT p.p_name, 
       p.p_mfgr, 
       p.p_type, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       n.n_name AS nation_name,
       COALESCE(ROUND(AVG(s.s_acctbal), 2), 0) AS avg_supplier_balance,
       COUNT(DISTINCT so.o_orderkey) AS order_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN LargestOrders so ON l.l_orderkey = so.o_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_size > 10
  AND p.p_retailprice < 100.00
  AND n.n_regionkey IS NOT NULL
GROUP BY p.p_name, p.p_mfgr, p.p_type, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
ORDER BY total_revenue DESC
LIMIT 10;
