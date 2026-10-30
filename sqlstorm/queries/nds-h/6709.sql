
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_partkey) AS part_supply_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) 
        FROM orders o2
    )
),
SalesData AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       SUM(rs.part_supply_count) AS total_suppliers, 
       COUNT(h.o_orderkey) AS high_value_orders,
       SUM(sd.total_sales) AS total_sales,
       AVG(sd.order_count) AS avg_orders_per_customer
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN HighValueOrders h ON h.o_custkey = s.s_nationkey
JOIN SalesData sd ON sd.c_custkey = s.s_nationkey
GROUP BY r.r_name
ORDER BY total_suppliers DESC, high_value_orders DESC;
