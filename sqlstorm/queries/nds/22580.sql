
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
combined_summary AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(ss.total_net_paid, 0) AS total_net_paid,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        (COALESCE(ss.total_net_paid, 0) - COALESCE(rs.total_return_amt, 0)) AS net_spent
    FROM customer_details cd
    LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN returns_summary rs ON cd.c_customer_sk = rs.sr_customer_sk
    WHERE cd.ranking <= 10
),
income_distribution AS (
    SELECT 
        CASE 
            WHEN net_spent < 100 THEN 'Low'
            WHEN net_spent BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS income_band,
        COUNT(*) AS customer_count
    FROM combined_summary
    GROUP BY CASE 
        WHEN net_spent < 100 THEN 'Low'
        WHEN net_spent BETWEEN 100 AND 500 THEN 'Medium'
        ELSE 'High'
    END
)
SELECT 
    id.income_band, 
    id.customer_count, 
    ROW_NUMBER() OVER (ORDER BY id.customer_count DESC) AS income_rank
FROM income_distribution id
WHERE id.customer_count > 5
ORDER BY id.customer_count DESC;
