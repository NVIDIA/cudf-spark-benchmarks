
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS average_order_value,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2400 AND 2405
    GROUP BY ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ss.total_sales,
        ss.order_count,
        ss.average_order_value,
        ss.unique_items
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.total_sales,
    cd.order_count,
    cd.average_order_value,
    cd.unique_items,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM customer_details cd
JOIN customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
WHERE cd.total_sales > 1000
ORDER BY cd.total_sales DESC
LIMIT 50;
