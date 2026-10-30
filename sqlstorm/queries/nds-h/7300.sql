WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 10000
), DetailedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice
    FROM lineitem l
    JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
)
SELECT r.r_name, COUNT(DISTINCT d.l_orderkey) AS total_orders, SUM(d.l_extendedprice) AS total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN DetailedLineItems d ON ps.ps_partkey = d.l_partkey
GROUP BY r.r_name
ORDER BY total_revenue DESC;
