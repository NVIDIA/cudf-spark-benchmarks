WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (ORDER BY s.s_acctbal DESC) AS RankByBalance
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartSupplierSummary AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount,
           SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS TotalCustomers,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
       AVG(ps.TotalSupplyCost) AS AvgSupplyCost,
       MAX(sd.RankByBalance) AS MaxSupplierBalance
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN PartSupplierSummary ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY TotalRevenue DESC
LIMIT 10;