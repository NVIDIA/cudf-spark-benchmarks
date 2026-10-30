WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalSupplyCost DESC
    LIMIT 10
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, COALESCE(co.OrderCount, 0) AS OrderCount, COALESCE(co.TotalSpent, 0) AS TotalSpent
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    ORDER BY TotalSpent DESC
    LIMIT 5
)
SELECT ts.c_name AS TopCustomerName, ts.OrderCount, ts.TotalSpent AS AmountSpent, rs.s_name AS TopSupplierName, rs.TotalSupplyCost
FROM TopCustomers ts
JOIN RankedSuppliers rs ON ts.TotalSpent > 0
ORDER BY ts.TotalSpent DESC, rs.TotalSupplyCost DESC;