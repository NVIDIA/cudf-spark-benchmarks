
WITH  processed_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        wd.wd_income,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            hd.hd_demo_sk, 
            SUM(CASE 
                WHEN ib.ib_upper_bound IS NOT NULL AND ib.ib_lower_bound IS NOT NULL THEN 
                    (ib.ib_upper_bound + ib.ib_lower_bound) / 2 
                ELSE 
                    0 
            END) AS wd_income
        FROM household_demographics hd
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY hd.hd_demo_sk
    ) wd ON wd.hd_demo_sk = cd.cd_demo_sk
), recent_sales AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS orders_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT 
            d_date_sk 
        FROM date_dim
        WHERE d_year = 2023 AND d_dow IN (1, 3, 5)
    )
    GROUP BY ws.ws_bill_customer_sk
), categorized_sales AS (
    SELECT 
        p.customer_id,
        CASE
            WHEN p.total_profit > 1000 THEN 'High Value'
            WHEN p.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_category,
        p.orders_count
    FROM recent_sales p
)
SELECT 
    pc.c_first_name,
    pc.c_last_name,
    pc.cd_gender,
    cs.customer_category,
    cs.orders_count
FROM processed_customers pc
LEFT JOIN categorized_sales cs ON pc.c_customer_sk = cs.customer_id
WHERE pc.rn <= 5 AND (pc.cd_marital_status IS NULL OR pc.cd_marital_status <> 'S')
ORDER BY pc.cd_purchase_estimate DESC, pc.c_last_name
LIMIT 10;
