WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
top_suppliers AS (
    SELECT ss.*, n.n_name, r.r_name
    FROM supplier_summary ss
    JOIN nation n ON ss.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
)
SELECT ts.s_name AS supplier_name, ts.total_supply_cost AS supplier_total_cost, co.c_name AS customer_name, SUM(co.order_revenue) AS total_revenue
FROM top_suppliers ts
JOIN customer_orders co ON ts.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
GROUP BY ts.s_name, ts.total_supply_cost, co.c_name
HAVING SUM(co.order_revenue) > 100000
ORDER BY ts.total_supply_cost DESC, total_revenue DESC;
