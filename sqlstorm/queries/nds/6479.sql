
WITH customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
           hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_net_profit, 
           COUNT(DISTINCT ws_order_number) AS order_count, 
           SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451600
    GROUP BY ws_bill_customer_sk
),
customer_sales AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status,
           SUM(ss.total_net_profit) AS customer_total_net_profit, 
           SUM(ss.order_count) AS total_orders,
           SUM(ss.total_quantity_sold) AS total_units_sold
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status
)
SELECT c.c_first_name, c.c_last_name, c.cd_gender, c.cd_marital_status, c.cd_education_status, 
       c.customer_total_net_profit, c.total_orders, c.total_units_sold
FROM customer_sales c
WHERE c.customer_total_net_profit > 1000 AND c.total_orders > 5
ORDER BY c.customer_total_net_profit DESC
LIMIT 10;
