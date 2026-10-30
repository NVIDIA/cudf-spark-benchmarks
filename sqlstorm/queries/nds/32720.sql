
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_store_sales,
        AVG(ss_net_profit) AS avg_store_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 90
    GROUP BY ss_store_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ss.total_sales,
    ss.total_orders,
    sss.total_store_sales,
    sss.avg_store_profit,
    sss.transaction_count
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
JOIN store_sales_summary sss ON ss.total_sales >= sss.total_store_sales
WHERE ci.gender_rank <= 10
ORDER BY ss.total_sales DESC, ss.total_orders DESC
LIMIT 50;
