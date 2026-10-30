
WITH  sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price * ws.ws_quantity AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
top_sales AS (
    SELECT
        ws_order_number,
        SUM(total_sales) AS total_order_sales
    FROM sales_data
    GROUP BY ws_order_number
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
annual_return_stat AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        coalesce(r.total_order_sales, 0) AS total_order_sales,
        ci.return_count,
        CASE
            WHEN return_count > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM customer_info ci
    LEFT JOIN top_sales r ON ci.c_customer_sk = r.ws_order_number
)
SELECT
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.cd_gender,
    a.cd_marital_status,
    a.cd_purchase_estimate,
    ROUND(a.total_order_sales, 2) AS total_order_sales,
    a.return_count,
    a.return_status,
    CASE
        WHEN a.return_count IS NULL THEN 'No Returns'
        ELSE CONCAT(a.return_count, ' Returns')
    END AS return_details
FROM annual_return_stat a
ORDER BY a.total_order_sales DESC
LIMIT 10;
