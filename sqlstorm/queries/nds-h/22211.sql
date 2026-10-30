WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
Decile AS (
    SELECT DISTINCT ntile(10) OVER (ORDER BY TotalCost) AS decile, TotalCost
    FROM RankedSuppliers
),
ActiveOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
)
SELECT r.s_name, 
       COALESCE(h.c_name, 'No High Value Customer') AS HighValueCustName,
       CASE WHEN d.decile IS NOT NULL THEN d.decile ELSE -1 END AS SupplierDecile,
       SUM(a.Revenue) AS TotalRevenue
FROM RankedSuppliers r
LEFT JOIN HighValueCustomers h ON r.s_suppkey = h.c_custkey
LEFT JOIN Decile d ON r.TotalCost = d.TotalCost
JOIN ActiveOrders a ON r.s_suppkey = a.o_custkey
WHERE r.rn = 1
GROUP BY r.s_name, h.c_name, d.decile
HAVING SUM(a.Revenue) > 10000
ORDER BY TotalRevenue DESC, r.s_name;
