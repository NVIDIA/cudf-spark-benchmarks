WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
TopCustomers AS (
    SELECT cust.c_custkey, cust.c_name, cust.o_orderdate, cust.TotalRevenue,
           RANK() OVER (PARTITION BY cust.o_orderdate ORDER BY cust.TotalRevenue DESC) AS RevenueRank
    FROM CustomerOrderSummary cust
)
SELECT r.r_name, COUNT(DISTINCT t.c_custkey) AS DistinctCustomerCount,
       AVG(t.TotalRevenue) AS AverageRevenue,
       SUM(t.TotalRevenue) AS TotalRevenueForRegion,
       MAX(s.TotalSupplyCost) AS MaxSupplierCost
FROM TopCustomers t
JOIN nation n ON t.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN RankedSuppliers s ON n.n_nationkey = s.s_nationkey
WHERE t.RevenueRank <= 5 AND t.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name
ORDER BY TotalRevenueForRegion DESC;