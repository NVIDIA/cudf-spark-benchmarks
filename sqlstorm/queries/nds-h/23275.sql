WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice,
           ROW_NUMBER() OVER(PARTITION BY o_custkey ORDER BY o_orderdate DESC) as order_rank
    FROM orders
    WHERE o_orderstatus IN ('O', 'F')
), 
FilteredLineItems AS (
    SELECT l.*, 
           (l_extendedprice * (1 - l_discount)) AS effective_price,
           DENSE_RANK() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) as price_rank
    FROM lineitem l
    WHERE l_returnflag = 'N' AND l_linestatus = 'O' 
      AND l_quantity > (SELECT AVG(l_quantity) FROM lineitem) 
), 
SupplierRating AS (
    SELECT ps.ps_suppkey, 
           AVG(s.s_acctbal) AS avg_acctbal,
           COUNT(DISTINCT ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 3
) 
SELECT n.n_name, 
       r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(ol.effective_price) AS total_revenue,
       CASE 
           WHEN SUM(ol.effective_price) IS NULL THEN 'No Revenue'
           ELSE 'Revenue Generated'
       END AS revenue_status,
       sr.avg_acctbal
FROM FilteredLineItems ol
JOIN OrderHierarchy oh ON ol.l_orderkey = oh.o_orderkey
JOIN customer c ON oh.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SupplierRating sr ON ol.l_suppkey = sr.ps_suppkey
WHERE DATE_PART('year', oh.o_orderdate) = 1997
AND n.n_name IN (SELECT DISTINCT n_name FROM nation WHERE n_regionkey IN (1, 2, 3))
GROUP BY n.n_name, r.r_name, sr.avg_acctbal
HAVING SUM(ol.effective_price) > (SELECT AVG(l_extendedprice) FROM lineitem)
ORDER BY total_revenue DESC, customer_count ASC;