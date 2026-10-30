
WITH  sales_trend AS (
    SELECT ws_sold_date_sk, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT ws_sold_date_sk, SUM(ws_ext_sales_price) 
    FROM web_sales
    WHERE ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_sold_date_sk
),
customer_summary AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           COALESCE(MAX(ws.ws_net_profit), 0) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT ca.ca_city,
       SUM(st.total_sales) AS city_total_sales,
       COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
       AVG(cs.total_net_profit) AS avg_customer_profit,
       STRING_AGG(CONCAT(cs.c_first_name, ' ', cs.c_last_name), ', ') AS customer_names
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN sales_trend st ON st.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
LEFT JOIN customer_summary cs ON cs.c_customer_sk = c.c_customer_sk
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city
HAVING SUM(st.total_sales) > (SELECT AVG(total_sales) FROM sales_trend)
ORDER BY city_total_sales DESC
LIMIT 10;
