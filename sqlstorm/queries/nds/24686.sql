
WITH  address_rank AS (
    SELECT ca_address_sk, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
),
customer_distribution AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           CASE WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown' 
                ELSE CASE 
                    WHEN cd.cd_purchase_estimate < 500 THEN 'Low'
                    WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium'
                    ELSE 'High' 
                END 
           END AS purchase_category,
           a.ca_city, a.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_data AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
sales_distribution AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           c.cd_gender, 
           c.cd_marital_status, 
           c.purchase_category, 
           c.ca_city, 
           c.ca_state,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.order_count, 0) AS order_count,
           CASE 
               WHEN COALESCE(sd.total_sales, 0) = 0 THEN 'No Sales'
               WHEN COALESCE(sd.total_sales, 0) < 1000 THEN 'Low Sales'
               WHEN COALESCE(sd.total_sales, 0) < 5000 THEN 'Moderate Sales'
               ELSE 'High Sales'
           END AS sales_category
    FROM customer_distribution c
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
top_customers AS (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) as sales_rank
    FROM sales_distribution
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.ca_city, 
    tc.ca_state, 
    tc.purchase_category, 
    tc.total_sales, 
    tc.order_count, 
    tc.sales_category
FROM top_customers tc
WHERE tc.sales_rank <= 10 AND 
      (tc.purchase_category = 'High' OR 
       (tc.purchase_category = 'Medium' AND tc.order_count > 3))
ORDER BY tc.ca_state, tc.total_sales DESC;
