
WITH customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_sales
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY cs.total_sales DESC
    LIMIT 10
),
sales_details AS (
    SELECT tc.c_customer_sk, tc.c_first_name, tc.c_last_name, 
           ws.ws_sales_price, ws.ws_quantity, ws.ws_sold_date_sk, 
           dd.d_date
    FROM top_customers tc
    JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    ORDER BY tc.c_customer_sk, ws.ws_sold_date_sk
)
SELECT td.c_customer_sk, td.c_first_name, td.c_last_name, 
       SUM(td.ws_sales_price * td.ws_quantity) AS total_amount_spent,
       MIN(td.d_date) AS first_purchase_date,
       MAX(td.d_date) AS last_purchase_date
FROM sales_details td
GROUP BY td.c_customer_sk, td.c_first_name, td.c_last_name
ORDER BY total_amount_spent DESC;
