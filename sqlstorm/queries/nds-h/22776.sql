
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderdate >= (CAST('1998-10-01' AS DATE) - INTERVAL '1 month')
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Unknown'
               WHEN c.c_acctbal > 10000 THEN 'Gold'
               WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Silver'
               ELSE 'Bronze'
           END AS cust_class
    FROM customer c
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name,
           COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT rc.c_name AS cust_name, rc.cust_class, 
       ps.p_name, ps.total_avail_qty,
       CASE 
           WHEN ps.total_avail_qty > 0 THEN 'Available'
           ELSE 'Unavailable'
       END AS availability_status,
       MAX(l.l_discount) AS max_discount_rate
FROM HighValueCustomers rc
JOIN RecentOrders ro ON rc.c_custkey = ro.o_custkey
JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN PartSupplierInfo ps ON ps.p_partkey = l.l_partkey
JOIN RankedSuppliers rs ON rc.c_custkey = rs.s_suppkey
WHERE rc.cust_class IN ('Gold', 'Silver')
  AND (ps.total_supply_value IS NULL OR ps.total_supply_value > 1000)
GROUP BY rc.c_name, rc.cust_class, ps.p_name, ps.total_avail_qty
HAVING COUNT(*) > 5
ORDER BY rc.cust_class DESC, ps.total_avail_qty DESC
LIMIT 50 OFFSET 10;
