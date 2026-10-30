WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s 
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01'
)
SELECT p.p_partkey, p.p_name, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
       CASE 
           WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
           ELSE 'Total Revenue: ' || CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS STRING)
       END AS revenue_summary
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
  AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY p.p_partkey, p.p_name, s.s_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY revenue DESC
LIMIT 10;