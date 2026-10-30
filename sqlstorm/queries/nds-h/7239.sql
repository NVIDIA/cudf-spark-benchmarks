WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1998-01-01'
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS TotalSupplied, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(ps.ps_partkey) > 5
)
SELECT r.r_name AS Region, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue, 
       COUNT(DISTINCT o.o_orderkey) AS OrderCount,
       COUNT(DISTINCT c.c_custkey) AS CustomerCount,
       COUNT(DISTINCT ss.s_suppkey) AS SupplierCount
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SupplierStats ss ON l.l_suppkey = ss.s_suppkey
WHERE l.l_shipdate >= DATE '1997-04-01' 
  AND l.l_shipdate < DATE '1997-10-01'
GROUP BY r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY Revenue DESC;