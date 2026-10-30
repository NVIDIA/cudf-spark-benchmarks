WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.rank <= 5
)
SELECT c.c_name AS CustomerName, 
       COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
       MAX(s.s_acctbal) AS MaxSupplierBalance,
       CASE WHEN AVG(l.l_discount) IS NULL THEN 0 ELSE AVG(l.l_discount) END AS AvgDiscount
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
WHERE o.o_orderstatus = 'F'
AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY TotalRevenue DESC
LIMIT 10;