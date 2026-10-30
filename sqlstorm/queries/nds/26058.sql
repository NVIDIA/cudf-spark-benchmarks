WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), item_info AS (
    SELECT 
        i.i_item_sk,
        TRIM(i.i_item_desc) AS item_description,
        REPLACE(i.i_color, ' ', '-') AS formatted_color,
        UPPER(i.i_brand) AS upper_brand
    FROM item i
), sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ii.item_description,
    ii.formatted_color,
    ii.upper_brand,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.avg_net_profit, 0) AS avg_net_profit,
    COALESCE(ss.order_count, 0) AS order_count
FROM customer_info ci
LEFT JOIN item_info ii ON ci.c_customer_sk = ii.i_item_sk  
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY ci.full_name, total_sales DESC;