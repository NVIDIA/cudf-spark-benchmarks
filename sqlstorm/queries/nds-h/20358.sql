
WITH  SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM SupplierCTE s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.Rank <= 5
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount,
           SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name 
    FROM CustomerOrders c 
    WHERE c.TotalSpent > 5000
),
NationData AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
FinalSelection AS (
    SELECT ns.n_name, ns.SupplierCount, ts.TotalSupplyCost 
    FROM NationData ns
    LEFT JOIN TopSuppliers ts ON ns.SupplierCount > 1
)
SELECT ns.n_name, 
       COALESCE(SUM(CASE WHEN (ns.SupplierCount IS NULL AND ts.TotalSupplyCost IS NOT NULL) THEN 1 ELSE 0 END), 0) AS CountNullSuppliers,
       COALESCE(AVG(ts.TotalSupplyCost), 0) AS AverageSupplyCost,
       CASE 
           WHEN ns.n_name IS NOT NULL THEN 'Nation Exists'
           ELSE 'Nation Not Found' 
       END AS NationExistenceCheck,
       'This is a ' || CASE WHEN COUNT(ns.n_name) = 0 THEN 'zero' ELSE 'non-zero' END || ' count of nations.' AS NationCountDescription
FROM FinalSelection ns
FULL OUTER JOIN TopSuppliers ts ON ts.TotalSupplyCost > 0
WHERE (ns.SupplierCount IS NOT NULL OR ts.TotalSupplyCost IS NOT NULL)
GROUP BY ns.n_name, ns.SupplierCount
HAVING COUNT(ns.n_name) > 0
ORDER BY CountNullSuppliers DESC, AverageSupplyCost ASC;
