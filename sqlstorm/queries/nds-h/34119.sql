
WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), RecentOrders AS (
    SELECT c.c_custkey, c.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.OrderRank <= 5
), SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS TotalAvailable, 
           AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, s.s_name, ss.TotalAvailable, ss.AvgSupplyCost
    FROM part p
    JOIN SupplierStats ss ON p.p_partkey = ss.ps_partkey
    JOIN supplier s ON ss.ps_suppkey = s.s_suppkey
    WHERE ss.TotalAvailable > 100
), CustomerRevenue AS (
    SELECT co.c_custkey, SUM(co.o_totalprice) AS TotalSpent
    FROM RecentOrders co
    GROUP BY co.c_custkey
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, cr.TotalSpent
    FROM customer c
    JOIN CustomerRevenue cr ON c.c_custkey = cr.c_custkey
    WHERE cr.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerRevenue)
)
SELECT pc.p_partkey, pc.p_name, pc.p_brand, tc.c_name, tc.TotalSpent
FROM PartSuppliers pc
LEFT JOIN TopCustomers tc ON pc.p_brand = SUBSTRING(tc.c_name, 1, 3)
WHERE tc.TotalSpent IS NOT NULL
ORDER BY pc.p_partkey, tc.TotalSpent DESC;
