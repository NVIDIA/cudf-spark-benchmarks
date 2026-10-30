WITH SupplierSummary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(od.total_order_value) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
Benchmark AS (
    SELECT c.c_custkey,
           c.c_name,
           coalesce(c.total_orders, 0) AS total_orders,
           coalesce(c.total_spent, 0) AS total_spent,
           ss.total_available,
           ss.avg_supply_cost
    FROM CustomerOrders c
    LEFT JOIN SupplierSummary ss ON ss.total_available > 0
)
SELECT b.c_custkey,
       b.c_name,
       b.total_orders,
       b.total_spent,
       b.total_available,
       b.avg_supply_cost,
       CASE 
           WHEN b.total_spent > 10000 THEN 'High Value' 
           WHEN b.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value' 
           ELSE 'Low Value' 
       END AS customer_value_segment
FROM Benchmark b
WHERE b.total_orders > 5
ORDER BY b.total_spent DESC
LIMIT 50;

