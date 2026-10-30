
WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           n.n_name AS nation, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderStats AS (
    SELECT o.o_custkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_order_value,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT c.c_name, 
       ss.nation, 
       ss.total_parts, 
       ss.total_supply_value, 
       os.total_orders, 
       os.total_order_value,
       os.last_order_date
FROM customer c
JOIN SupplierStats ss ON c.c_custkey = ss.s_suppkey
JOIN OrderStats os ON c.c_custkey = os.o_custkey
WHERE ss.total_supply_value > 10000 
  AND os.total_orders > 5
ORDER BY ss.total_supply_value DESC, os.total_order_value DESC
LIMIT 10;
