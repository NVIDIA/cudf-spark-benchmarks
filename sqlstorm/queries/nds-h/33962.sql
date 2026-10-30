
WITH  OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
), SupplierRank AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
           RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), RegionSales AS (
    SELECT n.n_nationkey, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_name
), LineItemAnalysis AS (
    SELECT l.l_orderkey, 
           COUNT(CASE WHEN l.l_discount > 0 THEN 1 END) AS discount_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name AS region, 
       s.s_name AS supplier_name,
       SUM(ls.net_sales) AS total_net_sales,
       COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
       MAX(s.total_supplycost) AS max_supplycost,
       AVG(s.total_supplycost) AS avg_supplycost
FROM RegionSales r
LEFT JOIN SupplierRank s ON r.n_nationkey = s.s_suppkey
JOIN LineItemAnalysis ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '1997-01-01')
LEFT JOIN OrderCTE o ON o.o_orderkey = ls.l_orderkey
WHERE s.supplier_rank <= 5
GROUP BY r.r_name, s.s_name
HAVING SUM(ls.net_sales) > 10000 OR MAX(s.total_supplycost) IS NULL
ORDER BY total_net_sales DESC;
