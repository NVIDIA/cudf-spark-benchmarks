WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
RecentOrders AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY o.o_orderkey
    HAVING COUNT(l.l_linenumber) > 5
)
SELECT r.s_suppkey, r.s_name, r.s_acctbal, h.c_custkey, h.c_name, 
       o.o_orderkey, o.line_item_count
FROM RankedSuppliers r
JOIN HighValueCustomers h ON r.rank = 1
JOIN RecentOrders o ON o.line_item_count > 5
WHERE r.s_acctbal > 5000
ORDER BY r.s_acctbal DESC, h.total_spent DESC;