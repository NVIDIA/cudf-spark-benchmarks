
WITH  sale_dates AS (
    SELECT d_date_sk, d_date, ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_date) AS rn
    FROM date_dim
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
), 
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           COALESCE(hd.hd_buy_potential, 'Unknown') AS buying_potential,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_buy_potential
), 
sales_summary AS (
    SELECT s.ss_sold_date_sk, 
           SUM(ss_ext_sales_price) AS total_sales, 
           SUM(ss_net_profit) AS total_profit
    FROM store_sales s
    GROUP BY s.ss_sold_date_sk
), 
top_customers AS (
    SELECT c.*, 
           DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM customer_info c
    WHERE total_spent > (
        SELECT AVG(total_spent) 
        FROM customer_info
    )
)
SELECT d.d_date, 
       COALESCE(ss.total_sales, 0) AS total_sales, 
       COALESCE(ss.total_profit, 0) AS total_profit,
       tc.c_first_name,
       tc.c_last_name,
       tc.buying_potential
FROM sale_dates d
LEFT JOIN sales_summary ss ON d.d_date_sk = ss.ss_sold_date_sk
LEFT JOIN top_customers tc ON tc.spend_rank <= 10
ORDER BY d.d_date DESC, total_sales DESC;
