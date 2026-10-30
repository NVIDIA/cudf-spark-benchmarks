
WITH customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name || ' ' || c.c_last_name AS full_name,
           cd.cd_gender,
           ca.ca_city,
           ca.ca_state,
           ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
city_sales AS (
    SELECT ci.full_name,
           ci.ca_city,
           ci.ca_state,
           ci.ca_country,
           COALESCE(sd.total_sales, 0) AS total_sales
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
),
ranked_sales AS (
    SELECT full_name,
           ca_city,
           ca_state,
           ca_country,
           total_sales,
           RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM city_sales
)
SELECT ca_city,
       COUNT(full_name) AS customer_count,
       SUM(total_sales) AS total_city_sales,
       MAX(sales_rank) AS max_sales_rank,
       AVG(total_sales) AS avg_sales_per_customer
FROM ranked_sales
GROUP BY ca_city
ORDER BY total_city_sales DESC
LIMIT 10;
