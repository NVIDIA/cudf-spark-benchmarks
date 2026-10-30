WITH recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_nationkey
),
nation_revenues AS (
    SELECT n.n_nationkey, n.n_name, SUM(ro.total_revenue) AS nation_revenue
    FROM recent_orders ro
    JOIN nation n ON ro.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
top_nations AS (
    SELECT n_nationkey, n_name, nation_revenue,
           RANK() OVER (ORDER BY nation_revenue DESC) AS revenue_rank
    FROM nation_revenues
)
SELECT tn.n_name, tn.nation_revenue, p.p_name, ps.ps_supplycost, s.s_name
FROM top_nations tn
JOIN partsupp ps ON tn.n_nationkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE tn.revenue_rank <= 5
ORDER BY tn.nation_revenue DESC, p.p_retailprice ASC;