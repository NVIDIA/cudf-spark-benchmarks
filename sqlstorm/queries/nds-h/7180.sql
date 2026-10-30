WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
orders_summary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT n.n_name, r.r_name, t.s_name, o.order_count, o.total_spent
FROM top_suppliers t
JOIN supplier s ON t.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN orders_summary o ON o.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = n.n_nationkey
)
WHERE o.total_spent > 10000
ORDER BY o.total_spent DESC, t.total_cost DESC;
