WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
lineitem_details AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(lo.total_line_value) AS total_spent
    FROM customer c
    JOIN recent_orders ro ON c.c_custkey = ro.o_custkey
    JOIN lineitem_details lo ON ro.o_orderkey = lo.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cs.c_name, cs.total_spent, ts.s_name, ts.total_supply_cost
FROM customer_summary cs
JOIN top_suppliers ts ON cs.total_spent > ts.total_supply_cost
ORDER BY cs.total_spent DESC, ts.total_supply_cost ASC;