WITH  sales_data AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
ranked_sales AS (
    SELECT sd.o_orderkey, sd.o_orderdate, sd.total_revenue,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM sd.o_orderdate) ORDER BY sd.total_revenue DESC) AS revenue_rank
    FROM sales_data sd
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT r.r_name,
       COALESCE(SUM(sd.total_revenue), 0) AS region_revenue,
       COUNT(DISTINCT tc.c_custkey) AS unique_customers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN sales_data sd ON p.p_partkey = sd.o_orderkey
LEFT JOIN top_customers tc ON tc.total_spent > 5000
GROUP BY r.r_name
HAVING COUNT(DISTINCT tc.c_custkey) IS NOT NULL
ORDER BY region_revenue DESC, r.r_name;