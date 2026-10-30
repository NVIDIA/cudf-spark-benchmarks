
WITH customer_stats AS (
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
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS total_returned_items
    FROM store_returns
    GROUP BY sr_customer_sk
),
combined_data AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_sales,
        ss.total_orders,
        COALESCE(rs.total_returns, 0) AS total_returns,
        cs.gender_rank,
        ss.total_sales - COALESCE(rs.total_returns, 0) AS net_sales
    FROM customer_stats cs
    LEFT JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN returns_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    cs.cd_gender,
    c.total_sales,
    c.total_orders,
    c.total_returns,
    c.net_sales,
    CASE
        WHEN c.gender_rank <= 5 THEN 'Top Buyer'
        ELSE 'Regular Buyer'
    END AS buyer_category
FROM combined_data c
JOIN customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
WHERE c.total_sales IS NOT NULL
    AND c.total_sales > 1000
ORDER BY c.net_sales DESC
LIMIT 100;
