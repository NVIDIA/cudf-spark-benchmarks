WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supplycost DESC
    LIMIT 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_spent
    FROM customer_orders co
    JOIN customer c ON c.c_custkey = co.c_custkey
    ORDER BY co.total_spent DESC
    LIMIT 10
)
SELECT ts.s_name AS supplier_name, tc.c_name AS customer_name, tc.total_spent
FROM top_suppliers ts
JOIN lineitem l ON l.l_suppkey = ts.s_suppkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
JOIN top_customers tc ON tc.c_custkey = o.o_custkey
WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
ORDER BY ts.s_name, tc.total_spent DESC;