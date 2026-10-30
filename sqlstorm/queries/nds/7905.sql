
WITH customer_data AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ca_city,
        ca_state,
        ca_country
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS average_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
popular_items AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS times_sold
    FROM web_sales
    GROUP BY ws_item_sk
    ORDER BY times_sold DESC
    LIMIT 10
),
final_report AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        ss.total_sales,
        ss.order_count,
        ss.average_order_value,
        pi.times_sold
    FROM customer_data AS cd
    LEFT JOIN sales_summary AS ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN popular_items AS pi ON ss.ws_bill_customer_sk IS NOT NULL
)

SELECT 
    *,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM final_report
WHERE total_sales > 0
ORDER BY sales_rank;
