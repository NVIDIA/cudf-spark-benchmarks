
WITH ranked_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT r.c_customer_sk,
           r.c_first_name,
           r.c_last_name,
           r.rank,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM ranked_customers AS r
    LEFT JOIN web_sales AS ws ON r.c_customer_sk = ws.ws_bill_customer_sk
    WHERE r.rank <= 10
    GROUP BY r.c_customer_sk, r.c_first_name, r.c_last_name, r.rank
),
customer_locations AS (
    SELECT c.c_customer_sk,
           ca.ca_city,
           ca.ca_state,
           COUNT(*) AS location_count
    FROM customer AS c
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state
)
SELECT tc.c_first_name,
       tc.c_last_name,
       tc.total_sales,
       tc.order_count,
       cl.ca_city,
       cl.ca_state,
       cl.location_count
FROM top_customers AS tc
JOIN customer_locations AS cl ON tc.c_customer_sk = cl.c_customer_sk
WHERE tc.total_sales > 1000
ORDER BY tc.total_sales DESC, cl.location_count DESC
LIMIT 50;
