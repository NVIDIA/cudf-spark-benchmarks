WITH  OrderCTE AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_sequence
    FROM orders
    WHERE o_orderstatus IN ('O', 'F')
), SupplierData AS (
    SELECT s.s_suppkey, s.s_name, AVG(s.s_acctbal) AS avg_acctbal, 
           MIN(s.s_acctbal) AS min_acctbal, MAX(s.s_acctbal) AS max_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), LineItemAnalytics AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returns_count,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    GROUP BY l.l_orderkey
), RegionSuppliers AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT od.order_sequence, od.o_orderkey, od.o_orderdate, od.o_totalprice, 
       li.total_revenue, li.returns_count, li.unique_parts,
       s.avg_acctbal, s.min_acctbal, s.max_acctbal,
       r.supplier_count, 
       CASE 
           WHEN od.o_orderdate IS NULL THEN 'Missing Date'
           WHEN od.o_orderdate < cast('1998-10-01' as date) - INTERVAL '365 days' THEN 'Old Order' 
           ELSE 'Recent Order'
       END AS order_age_category,
       COALESCE(NULLIF(s.avg_acctbal, 0), (SELECT MIN(s2.s_acctbal) FROM supplier s2)) AS adjusted_avg_acctbal
FROM OrderCTE od
LEFT JOIN LineItemAnalytics li ON od.o_orderkey = li.l_orderkey
LEFT JOIN SupplierData s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_container = 'BOX' LIMIT 1) LIMIT 1)
LEFT JOIN RegionSuppliers r ON r.supplier_count > 10
WHERE (od.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) 
       OR od.o_orderstatus = 'F') 
AND EXISTS (SELECT 1 FROM customer c WHERE c.c_custkey = od.o_custkey 
            AND c.c_acctbal > 1000 
            AND c.c_mktsegment = 'BUILDING')
ORDER BY od.o_orderdate DESC, li.total_revenue DESC
LIMIT 100;