
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
top_sales AS (
    SELECT *
    FROM sales_data
    WHERE sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        c.c_current_addr_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer_address ca
    WHERE ca.ca_city IS NOT NULL
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    ts.total_quantity,
    ts.total_sales
FROM top_sales ts
JOIN customer_info ci ON ts.ws_item_sk = ci.c_customer_sk
LEFT JOIN address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
WHERE ts.total_sales > 1000
ORDER BY ts.total_sales DESC, ts.total_quantity ASC;
