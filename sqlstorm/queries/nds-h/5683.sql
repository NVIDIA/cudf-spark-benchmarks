WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
), nation_average AS (
    SELECT n.n_nationkey, AVG(c.total_spent) AS average_spent
    FROM nation n
    JOIN customer_orders c ON n.n_nationkey = c.c_custkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, n.n_name, COUNT(DISTINCT cs.c_custkey) AS active_customers, SUM(o.o_totalprice) AS total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN customer_orders cs ON c.c_custkey = cs.c_custkey
JOIN top_suppliers ts ON o.o_custkey = ts.s_suppkey
WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
AND ts.total_cost > (SELECT AVG(average_spent) FROM nation_average)
GROUP BY r.r_name, n.n_name
ORDER BY total_revenue DESC;