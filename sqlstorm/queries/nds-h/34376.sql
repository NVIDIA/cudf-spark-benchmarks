WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
NationClients AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, n.n_name, 
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey, n.n_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FinalReport AS (
    SELECT nc.c_name AS customer_name, nc.n_name AS nation_name,
           COUNT(DISTINCT hvo.o_orderkey) AS high_value_orders,
           COALESCE(SUM(sc.ps_availqty), 0) AS total_supply_quantity
    FROM NationClients nc
    LEFT JOIN HighValueOrders hvo ON nc.c_custkey = hvo.o_orderkey
    LEFT JOIN SupplyChain sc ON nc.n_name = sc.s_name
    GROUP BY nc.c_name, nc.n_name
)
SELECT fr.customer_name, fr.nation_name, fr.high_value_orders, fr.total_supply_quantity
FROM FinalReport fr
ORDER BY fr.high_value_orders DESC, fr.total_supply_quantity DESC
LIMIT 10;
