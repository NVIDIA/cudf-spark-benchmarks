
WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(DISTINCT l.l_linenumber) AS line_item_count,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           os.total_order_value,
           COALESCE(l_max.line_item_count, 0) AS max_line_item_count
    FROM orders o
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    LEFT JOIN (
        SELECT o.o_orderkey,
               COUNT(l.l_linenumber) AS line_item_count
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY o.o_orderkey
    ) l_max ON o.o_orderkey = l_max.o_orderkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
    )
)
SELECT ss.s_name AS supplier_name,
       MAX(ss.total_available) AS total_available,
       AVG(ss.avg_supply_cost) AS avg_supply_cost,
       COUNT(hv.o_orderkey) AS high_value_order_count,
       SUM(hv.total_order_value) AS total_high_value_order_value
FROM SupplierStats ss
JOIN partsupp ps ON ss.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN HighValueOrders hv ON l.l_orderkey = hv.o_orderkey
GROUP BY ss.s_name
HAVING AVG(ss.avg_supply_cost) > 100
ORDER BY total_high_value_order_value DESC
LIMIT 10;
