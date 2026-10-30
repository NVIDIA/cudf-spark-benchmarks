WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 5
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalAmount,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Ranking
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT os.o_custkey, os.TotalAmount
    FROM OrderSummary os
    WHERE os.Ranking <= 10
)
SELECT p.p_name, p.p_retailprice, SUM(ps.ps_availqty) AS TotalAvailable, 
       COALESCE(SUM(ns.s_acctbal), 0) AS TotalSupplierBalance,
       AVG(NULLIF(ps.ps_supplycost, 0)) AS AvgSupplyCost
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier ns ON ps.ps_suppkey = ns.s_suppkey
LEFT JOIN TopCustomers tc ON ns.s_nationkey = tc.o_custkey
WHERE p.p_size BETWEEN 5 AND 15
GROUP BY p.p_name, p.p_retailprice
HAVING SUM(ps.ps_availqty) > 100
ORDER BY TotalAvailable DESC, p.p_name ASC
LIMIT 20;
