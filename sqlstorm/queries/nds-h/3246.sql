
WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS average_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_linenumber, l.l_discount, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM lineitem l
),
HighValueOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_nationkey
    FROM RecentOrders ro
    WHERE ro.o_totalprice > (SELECT AVG(o_totalprice) FROM RecentOrders)
)
SELECT r.n_name, COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count, 
       SUM(lid.l_extendedprice * (1 - lid.l_discount)) AS total_revenue,
       AVG(ps.average_supply_cost) AS avg_supply_cost_per_part
FROM HighValueOrders hvo
JOIN nation r ON r.n_nationkey = hvo.c_nationkey
LEFT JOIN LineItemDetails lid ON lid.l_orderkey = hvo.o_orderkey
LEFT JOIN PartSuppliers ps ON ps.ps_partkey = lid.l_partkey
GROUP BY r.n_name
HAVING COUNT(DISTINCT hvo.o_orderkey) > 0
ORDER BY total_revenue DESC
LIMIT 10;
