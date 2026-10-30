
WITH customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating, ca.ca_city, ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_data AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), 
activity_summary AS (
    SELECT cd.c_customer_sk, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
           SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM web_sales ws
    JOIN customer_data cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY cd.c_customer_sk
), 
final_summary AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.c_preferred_cust_flag, 
           cs.cd_gender, cs.cd_marital_status, cs.cd_purchase_estimate, cs.cd_credit_rating, 
           cs.ca_city, cs.ca_state, 
           asu.total_orders, asu.total_quantity, asu.total_spent, 
           COALESCE(sd.total_net_profit, 0) AS total_web_profit
    FROM customer_data cs
    LEFT JOIN activity_summary asu ON cs.c_customer_sk = asu.total_orders
    LEFT JOIN sales_data sd ON cs.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT * 
FROM final_summary 
WHERE total_spent > 1000 AND total_web_profit > 500 
ORDER BY total_spent DESC, total_web_profit DESC;
