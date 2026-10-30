WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
CustomerStats AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierPartStats AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT coalesce(r.n_name, 'Unknown') AS nation_name,
       SUM(COALESCE(lp.total_spent, 0)) AS total_revenue,
       AVG(CASE WHEN lp.total_orders > 0 THEN lp.total_orders ELSE NULL END) AS avg_orders_per_customer,
       MAX(sps.total_supply_value) AS max_supply_value,
       COUNT(DISTINCT ro.o_orderkey) AS total_orders_with_suppliers
FROM RankedOrders ro
LEFT JOIN CustomerStats lp ON ro.o_orderkey = lp.total_orders
LEFT JOIN supplier s ON s.s_suppkey = lp.c_custkey
LEFT JOIN nation r ON r.n_nationkey = s.s_nationkey
LEFT JOIN SupplierPartStats sps ON sps.ps_suppkey = s.s_suppkey
WHERE ro.order_rank <= 10
  AND (ro.o_orderstatus = 'F' OR ro.o_orderstatus = 'P')
GROUP BY r.n_name
ORDER BY total_revenue DESC
LIMIT 100;