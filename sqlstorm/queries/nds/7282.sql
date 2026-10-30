
WITH customer_sales AS (
    SELECT c.c_customer_id, SUM(ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 1500
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT c_customer_id
    FROM customer_sales
    WHERE total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
customer_details AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_dep_count
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_id IN (SELECT c_customer_id FROM high_value_customers)
),
address_details AS (
    SELECT ca.ca_state, ca.ca_city, COUNT(*) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_customer_id IN (SELECT c_customer_id FROM high_value_customers)
    GROUP BY ca.ca_state, ca.ca_city
),
final_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.ca_state,
        ad.ca_city,
        ad.customer_count
    FROM customer_details cd
    JOIN address_details ad ON cd.cd_dep_count = ad.customer_count
)
SELECT 
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_education_status,
    fs.ca_state,
    fs.ca_city,
    COUNT(*) AS high_value_customer_count
FROM final_summary fs
GROUP BY fs.cd_gender, fs.cd_marital_status, fs.cd_education_status, fs.ca_state, fs.ca_city
ORDER BY high_value_customer_count DESC;
