
WITH  sales_totals AS (
    SELECT ss_store_sk, 
           SUM(ss_net_paid) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions,
           RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ss_store_sk
),
top_stores AS (
    SELECT st.s_store_id,
           st.s_store_name,
           COALESCE(st.s_zip, 'Unknown') AS store_zip,
           st.s_city AS store_city,
           st.s_state AS store_state,
           COALESCE(ct.total_sales, 0) AS total_sales,
           COALESCE(ct.total_transactions, 0) AS total_transactions
    FROM store st
    LEFT JOIN sales_totals ct ON st.s_store_sk = ct.ss_store_sk
),
high_income_customers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           hd.hd_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound > 100000
),
customer_orders AS (
    SELECT c.c_customer_id,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY c.c_customer_id
),
unique_high_value_customers AS (
    SELECT ho.c_customer_id
    FROM high_income_customers ho
    JOIN customer_orders co ON ho.c_customer_id = co.c_customer_id
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
)
SELECT ts.store_zip,
       ts.store_city,
       ts.store_state,
       COUNT(DISTINCT uhvc.c_customer_id) AS unique_high_value_customer_count,
       SUM(ts.total_sales) AS aggregate_sales
FROM top_stores ts
JOIN unique_high_value_customers uhvc ON ts.total_transactions > 10
GROUP BY ts.store_zip, ts.store_city, ts.store_state
HAVING SUM(ts.total_sales) > 100000
ORDER BY unique_high_value_customer_count DESC NULLS LAST;
