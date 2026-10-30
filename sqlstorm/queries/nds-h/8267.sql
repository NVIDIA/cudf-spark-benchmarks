WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
top_n_cust_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(ro.total_revenue) AS total_customer_revenue
    FROM ranked_orders ro
    JOIN orders o ON ro.o_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE ro.revenue_rank <= 10
    GROUP BY c.c_custkey, c.c_name
)
SELECT c.c_name, c.total_customer_revenue, COUNT(DISTINCT o.o_orderkey) AS order_count
FROM top_n_cust_orders c
JOIN orders o ON c.c_custkey = o.o_custkey
GROUP BY c.c_name, c.total_customer_revenue
ORDER BY c.total_customer_revenue DESC
LIMIT 5;