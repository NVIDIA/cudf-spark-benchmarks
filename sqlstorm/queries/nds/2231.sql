
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        (SELECT COUNT(DISTINCT ws.ws_order_number)
         FROM web_sales ws
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_orders,
        (SELECT COUNT(DISTINCT sr_ticket_number)
         FROM store_returns sr
         WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_store_returns
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
high_value_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.gender_rank,
        cs.total_web_orders,
        cs.total_store_returns
    FROM customer_stats cs
    WHERE cs.cd_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate)
        FROM customer_demographics
    )
)
SELECT
    hvc.c_customer_sk,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    hvc.total_web_orders,
    hvc.total_store_returns,
    COALESCE(CAST(hvc.total_store_returns AS decimal) / NULLIF(hvc.total_web_orders, 0), 0) AS return_rate
FROM high_value_customers hvc
ORDER BY hvc.cd_purchase_estimate DESC, hvc.gender_rank
LIMIT 100
OFFSET 0;
