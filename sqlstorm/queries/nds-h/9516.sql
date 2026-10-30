
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY TotalCost DESC
    LIMIT 5
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 10
), ProductSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS SalesRevenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY p.p_partkey, p.p_name
    ORDER BY SalesRevenue DESC
    LIMIT 10
)
SELECT ts.s_name AS SupplierName,
       co.c_name AS CustomerName,
       ps.p_name AS ProductName,
       ps.SalesRevenue,
       co.TotalSpent
FROM TopSuppliers ts
JOIN CustomerOrders co ON co.c_custkey IS NOT NULL
JOIN ProductSales ps ON ps.SalesRevenue > 1000
ORDER BY co.TotalSpent DESC, ps.SalesRevenue DESC;
