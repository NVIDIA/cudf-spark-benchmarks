
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(LEFT(ca.ca_street_number, 5), ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', 
               ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM customer_details cd
    LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    cd_purchase_estimate,
    cd_credit_rating,
    total_sales,
    order_count,
    CONCAT('Total Spend: $', ROUND(total_sales, 2), ' across ', order_count, ' orders') AS sales_info
FROM combined_data
WHERE cd_gender = 'F' AND total_sales > 1000
ORDER BY total_sales DESC
LIMIT 10;
