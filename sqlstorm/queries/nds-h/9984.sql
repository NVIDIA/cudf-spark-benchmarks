
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(r.TotalSales) AS CustomerTotalSales
    FROM customer c
    JOIN RankedOrders r ON c.c_custkey = r.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY CustomerTotalSales DESC
    LIMIT 10
),
SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS SupplierTotalSales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
)
SELECT tc.c_name AS TopCustomer, ss.s_name AS SupplierName, tc.CustomerTotalSales, ss.SupplierTotalSales
FROM TopCustomers tc
JOIN SupplierSales ss ON tc.CustomerTotalSales > ss.SupplierTotalSales
ORDER BY tc.CustomerTotalSales DESC, ss.SupplierTotalSales DESC;
