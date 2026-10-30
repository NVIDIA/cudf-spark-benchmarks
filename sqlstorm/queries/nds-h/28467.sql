WITH region_sales AS (
    SELECT r.r_name AS region, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY r.r_name
),
customer_sales AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_sales AS (
    SELECT region, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM region_sales
),
top_customers AS (
    SELECT c.c_name, cs.customer_total,
           RANK() OVER (ORDER BY cs.customer_total DESC) AS customer_rank
    FROM customer_sales cs
    JOIN customer c ON c.c_custkey = cs.c_custkey
)
SELECT rs.region, rs.total_sales, tc.c_name AS top_customer, tc.customer_total
FROM ranked_sales rs
JOIN top_customers tc ON rs.sales_rank = tc.customer_rank
WHERE rs.sales_rank <= 5 AND tc.customer_rank <= 5
ORDER BY rs.total_sales DESC, tc.customer_total DESC;
