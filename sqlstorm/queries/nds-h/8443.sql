WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
), SupplierRanking AS (
    SELECT rs.s_suppkey, rs.s_name, RANK() OVER (ORDER BY rs.TotalSupplyCost DESC) AS SupplyRank
    FROM RankedSuppliers rs
), RevenueRanking AS (
    SELECT os.o_orderkey, os.o_orderdate, os.c_name, RANK() OVER (ORDER BY os.TotalRevenue DESC) AS RevenueRank
    FROM OrderSummary os
)
SELECT sr.s_name AS SupplierName, rr.c_name AS CustomerName, rr.o_orderdate AS OrderDate, 
       sr.SupplyRank, rr.RevenueRank
FROM SupplierRanking sr
JOIN RevenueRanking rr ON sr.SupplyRank <= 10 AND rr.RevenueRank <= 10
ORDER BY sr.SupplyRank, rr.RevenueRank;
