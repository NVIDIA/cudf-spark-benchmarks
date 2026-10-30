WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank,
           c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
TopOrders AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, c_nationkey
    FROM RankedOrders
    WHERE order_rank <= 5
),
SuppliersWithParts AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),
OrderLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, l.l_discount, l.l_quantity
    FROM lineitem l
    JOIN TopOrders t ON l.l_orderkey = t.o_orderkey
)
SELECT r.r_name, SUM(oli.l_extendedprice * (1 - oli.l_discount)) AS total_revenue, COUNT(DISTINCT oli.l_orderkey) AS total_orders,
       COUNT(DISTINCT sp.s_suppkey) AS total_suppliers
FROM OrderLineItems oli
JOIN SuppliersWithParts sp ON oli.l_partkey = sp.ps_partkey
JOIN nation n ON sp.s_suppkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;