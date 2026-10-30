WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS TotalAvailableQty, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(os.TotalRevenue) AS CustomerTotalRevenue
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY CustomerTotalRevenue DESC
    LIMIT 10
)
SELECT r.r_name AS Region, 
       SUM(si.TotalAvailableQty) AS TotalAvailableQty,
       SUM(si.TotalSupplyCost) AS TotalSupplyCost,
       COUNT(DISTINCT tc.c_custkey) AS TopCustomerCount
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplierinfo si ON si.s_nationkey = n.n_nationkey
JOIN TopCustomers tc ON si.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
GROUP BY r.r_name
ORDER BY TotalAvailableQty DESC;