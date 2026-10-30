
WITH  nation_supply AS (
    SELECT n.n_name, s.s_suppkey, s.s_name, COUNT(*) AS total_supplies
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, s.s_suppkey, s.s_name
), top_nations AS (
    SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
    ORDER BY total_cost DESC
    LIMIT 5
), order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, c.c_mktsegment, o.o_orderdate
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), line_items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT t.n_name, n.total_supplies, o.o_orderkey, o.o_totalprice AS total_price, o.c_name, o.c_mktsegment, l.total_revenue
FROM top_nations t
JOIN nation_supply n ON t.n_name = n.n_name
JOIN order_summary o ON n.s_suppkey = o.o_orderkey
JOIN line_items l ON o.o_orderkey = l.l_orderkey
WHERE o.o_totalprice > 10000
ORDER BY t.total_cost DESC, l.total_revenue DESC;
