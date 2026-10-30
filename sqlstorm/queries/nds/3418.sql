
WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
),
aggregate_sales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit,
        AVG(sd.ws_sales_price) AS avg_sales_price
    FROM sales_data sd
    WHERE sd.sales_rank <= 5
    GROUP BY sd.ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
),
sales_summary AS (
    SELECT
        ai.ws_item_sk,
        ai.total_net_profit,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_credit_rating
    FROM aggregate_sales ai
    LEFT JOIN customer_info ci ON ci.gender_rank <= 10
    WHERE ai.total_net_profit > (SELECT AVG(total_net_profit) FROM aggregate_sales)
)
SELECT
    ss.ws_item_sk,
    ss.total_net_profit,
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.cd_gender,
    ss.cd_credit_rating
FROM sales_summary ss
WHERE ss.cd_credit_rating IS NOT NULL
ORDER BY ss.total_net_profit DESC, ss.cd_gender, ss.c_last_name
LIMIT 100;
