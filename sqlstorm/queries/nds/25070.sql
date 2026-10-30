
WITH customer_info AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status,
           ca.ca_city,
           ca.ca_state,
           ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
product_sales AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
sales_analysis AS (
    SELECT ci.full_name,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           ci.ca_city,
           ci.ca_state,
           ci.ca_country,
           COALESCE(ps.total_sales, 0) AS total_sales,
           CASE 
               WHEN COALESCE(ps.total_sales, 0) = 0 THEN 'No Sales'
               WHEN COALESCE(ps.total_sales, 0) < 100 THEN 'Low Sales'
               ELSE 'High Sales'
           END AS sales_category
    FROM customer_info ci
    LEFT JOIN product_sales ps ON ci.c_customer_sk = ps.ws_bill_customer_sk
)
SELECT ca.ca_city, 
       ca.ca_state, 
       COUNT(*) AS customer_count, 
       AVG(sa.total_sales) AS avg_sales
FROM sales_analysis sa
JOIN customer_address ca ON sa.ca_city = ca.ca_city AND sa.ca_state = ca.ca_state
GROUP BY ca.ca_city, ca.ca_state
ORDER BY customer_count DESC, avg_sales DESC
LIMIT 10;
