WITH SupplierAggregate AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sa.TotalSupplyCost
    FROM SupplierAggregate sa
    JOIN supplier s ON sa.s_suppkey = s.s_suppkey
    ORDER BY sa.TotalSupplyCost DESC
    LIMIT 10
),
TopCustomers AS (
    SELECT cust.c_custkey, cust.c_name, cust.OrderCount, cust.TotalSpent
    FROM CustomerOrders cust
    ORDER BY cust.TotalSpent DESC
    LIMIT 10
)
SELECT tc.c_name AS TopCustomer, ts.s_name AS TopSupplier, tc.TotalSpent, ts.TotalSupplyCost
FROM TopCustomers tc
CROSS JOIN TopSuppliers ts
WHERE tc.TotalSpent > 10000 AND ts.TotalSupplyCost > 50000
ORDER BY tc.TotalSpent DESC, ts.TotalSupplyCost DESC;
