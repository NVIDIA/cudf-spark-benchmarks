
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, COUNT(l.l_orderkey) AS item_count
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
)

SELECT r.r_name AS region_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
       COUNT(DISTINCT ho.c_custkey) AS high_value_customers,
       COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN RecentOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN HighValueCustomers ho ON ro.o_custkey = ho.c_custkey
GROUP BY r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 500000
ORDER BY revenue DESC;
