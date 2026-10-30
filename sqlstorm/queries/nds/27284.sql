
WITH expanded_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_gmt_offset
    FROM customer_address
),
demographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN expanded_addresses a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web'
            WHEN cs_bill_customer_sk IS NOT NULL THEN 'Catalog'
            WHEN ss_customer_sk IS NOT NULL THEN 'Store'
        END AS sales_channel,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales ws
    FULL JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    GROUP BY sales_channel
)

SELECT 
    d.c_first_name,
    d.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    d.cd_dep_count,
    d.cd_dep_employed_count,
    d.cd_dep_college_count,
    d.full_address,
    d.ca_city,
    d.ca_state,
    d.ca_zip,
    d.ca_country,
    s.sales_channel,
    s.total_orders,
    s.total_profit
FROM demographics d
JOIN sales_summary s ON s.sales_channel IS NOT NULL 
ORDER BY d.c_last_name, d.c_first_name;
