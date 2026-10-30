WITH SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, sum(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
), SupplierOrderSummary AS (
    SELECT sr.s_suppkey, sr.s_name, od.o_orderkey, od.order_value
    FROM SupplierRevenue sr
    JOIN partsupp ps ON sr.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
)
SELECT s.s_name, COUNT(DISTINCT so.o_orderkey) AS total_orders, SUM(so.order_value) AS total_order_value
FROM SupplierOrderSummary so
JOIN supplier s ON so.s_suppkey = s.s_suppkey
GROUP BY s.s_name
ORDER BY total_order_value DESC
LIMIT 10;