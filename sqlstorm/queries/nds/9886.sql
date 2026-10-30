
WITH top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss.ss_ext_sales_price) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_spent DESC
    LIMIT 10
),
monthly_sales AS (
    SELECT d.d_year, d.d_month_seq, SUM(ss.ss_ext_sales_price) AS monthly_total
    FROM date_dim d
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
    ORDER BY d.d_year, d.d_month_seq
),
sales_summary AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, t.monthly_total, t.d_year
    FROM top_customers c
    JOIN monthly_sales t ON c.total_spent >= 1000
)
SELECT s.c_first_name, s.c_last_name, s.d_year, s.monthly_total
FROM sales_summary s
ORDER BY s.d_year DESC, s.monthly_total DESC;
