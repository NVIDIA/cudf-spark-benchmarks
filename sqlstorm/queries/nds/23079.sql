
WITH  address_data AS (
    SELECT ca_address_sk, ca_address_id, ca_city, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS city_rank
    FROM customer_address
    WHERE ca_city IS NOT NULL
), 
sales_data AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS total_sales,
           COUNT(*) AS transaction_count
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
), 
customer_analysis AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, ad.ca_city,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.transaction_count, 0) AS transaction_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN address_data ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
), 
ranked_customers AS (
    SELECT *, 
           RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM customer_analysis
    WHERE total_sales > 1000
)
SELECT r.c_first_name, r.c_last_name, r.total_sales, r.sales_rank, r.ca_city
FROM ranked_customers r
WHERE r.sales_rank = 1 AND r.cd_gender = 'F' 
  AND r.cd_marital_status = 'M' 
  AND r.ca_city NOT IN (SELECT ca_city 
                        FROM customer_address 
                        WHERE ca_city IS NULL) 
  AND r.total_sales > COALESCE((SELECT AVG(total_sales) FROM ranked_customers), 0) 
                               * CASE WHEN r.cd_marital_status = 'M' THEN 1.5 ELSE 1 END
                     AND r.total_sales < (SELECT MAX(total_sales) 
                                          FROM ranked_customers) + 500
ORDER BY r.total_sales DESC;
