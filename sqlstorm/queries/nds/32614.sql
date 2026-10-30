
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_marital_status,
           cd.cd_gender,
           0 AS level,
           CAST(c.c_customer_sk AS VARCHAR(255)) AS path
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_marital_status,
           cd.cd_gender,
           ch.level + 1,
           CONCAT(ch.path, '->', c.c_customer_sk)
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_hierarchy ch ON ch.c_customer_sk = c.c_current_hdemo_sk
)
SELECT ca.ca_city,
       COUNT(DISTINCT c.c_customer_sk) AS num_customers,
       SUM(ws.ws_sales_price) AS total_sales,
       AVG(ws.ws_net_profit) AS avg_net_profit,
       STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_state = 'CA'
  AND (c.c_birth_year IS NULL OR c.c_birth_year > 1980)
  AND c.c_first_name IS NOT NULL
GROUP BY ca.ca_city
HAVING SUM(ws.ws_sales_price) > 10000
ORDER BY num_customers DESC
LIMIT 10 OFFSET 0;
