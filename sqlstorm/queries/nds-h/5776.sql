WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation, 
           DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name AS customer_name, 
           n.n_name AS nation, o.o_orderstatus
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE o.o_totalprice > 10000
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.s_name, r.nation, COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
       SUM(l.revenue) AS total_revenue, AVG(l.item_count) AS average_items_per_order
FROM RankedSuppliers r
JOIN HighValueOrders h ON r.s_suppkey = h.o_orderkey
JOIN LineItemDetails l ON h.o_orderkey = l.l_orderkey
WHERE r.rank <= 3
GROUP BY r.s_name, r.nation
ORDER BY total_revenue DESC, high_value_order_count DESC;
