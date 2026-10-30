WITH supplier_totals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT s.s_suppkey, st.total_cost, co.c_custkey, co.total_order_value
FROM supplier_totals st
JOIN supplier s ON st.s_suppkey = s.s_suppkey
JOIN customer_orders co ON co.total_order_value > 1000
ORDER BY st.total_cost DESC, co.total_order_value DESC
LIMIT 100;
