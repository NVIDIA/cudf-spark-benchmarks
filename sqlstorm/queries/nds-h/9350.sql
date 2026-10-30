WITH nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name, s.s_suppkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
customer_analysis AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_lineitem_price) AS total_spent
    FROM customer c
    JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
final_report AS (
    SELECT ns.n_name, cs.c_name, cs.total_spent, ns.total_supply_cost
    FROM nation_supplier ns
    JOIN customer_analysis cs ON ns.n_nationkey = cs.c_custkey
    WHERE ns.total_supply_cost > 100000
    ORDER BY total_spent DESC
)
SELECT n_name, c_name, total_spent, total_supply_cost
FROM final_report
LIMIT 50;