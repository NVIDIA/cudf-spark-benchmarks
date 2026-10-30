
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS part_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighVolumeSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.part_count
    FROM SupplierParts s
    WHERE s.part_count > 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT co.c_custkey, co.c_name, co.order_count, co.total_spent
    FROM CustomerOrders co
    WHERE co.total_spent > 10000
),
LineitemAnalysis AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY l.l_partkey
)
SELECT 
    hs.s_name,
    tc.c_name,
    la.total_quantity,
    la.avg_price,
    hs.part_count,
    tc.total_spent
FROM HighVolumeSuppliers hs
JOIN TopCustomers tc ON hs.part_count = 11
JOIN LineitemAnalysis la ON hs.s_suppkey = la.l_partkey
ORDER BY tc.total_spent DESC, hs.s_name;
