
WITH SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'O'
), RegionSupplier AS (
    SELECT r.r_regionkey, r.r_name, s.s_nationkey, SUM(ps.ps_supplycost) AS region_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_regionkey, r.r_name, s.s_nationkey
)

SELECT 
    co.c_name AS customer_name,
    rs.r_name AS region_name,
    SUM(s.total_supply_cost) AS total_supplier_cost,
    SUM(co.total_spent) AS total_customer_spent,
    COUNT(DISTINCT h.o_orderkey) AS high_value_order_count
FROM CustomerOrders co
JOIN RegionSupplier rs ON co.c_custkey = rs.s_nationkey
LEFT JOIN SupplierCosts s ON rs.s_nationkey = s.s_suppkey
JOIN HighValueOrders h ON co.c_custkey = h.o_custkey
WHERE co.total_orders > 5 AND co.total_spent IS NOT NULL
GROUP BY co.c_name, rs.r_name
HAVING SUM(s.total_supply_cost) < 50000
ORDER BY total_customer_spent DESC, customer_name ASC;
