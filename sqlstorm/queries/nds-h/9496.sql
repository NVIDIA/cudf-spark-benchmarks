WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
), TopOrders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, r.c_name, n.n_name AS nation_name
    FROM RankedOrders r
    JOIN nation n ON r.c_nationkey = n.n_nationkey
    WHERE r.order_rank <= 10
), OrderLineDetails AS (
    SELECT t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name, t.nation_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM TopOrders t
    LEFT JOIN lineitem l ON t.o_orderkey = l.l_orderkey
    GROUP BY t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name, t.nation_name
)
SELECT t.nation_name, COUNT(t.o_orderkey) AS order_count, AVG(t.total_revenue) AS avg_revenue
FROM OrderLineDetails t
GROUP BY t.nation_name
ORDER BY avg_revenue DESC;