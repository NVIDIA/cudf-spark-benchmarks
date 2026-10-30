
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
address_count AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses
    FROM
        customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        c.c_customer_sk
),
avg_spent AS (
    SELECT
        AVG(total_spent) AS average_spent
    FROM
        customer_stats
    WHERE
        total_orders > 0
),
high_value_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        ac.unique_addresses
    FROM
        customer_stats cs
    JOIN address_count ac ON cs.c_customer_sk = ac.c_customer_sk
    WHERE
        cs.total_spent > (SELECT average_spent FROM avg_spent)
        AND ac.unique_addresses IS NOT NULL
),
shipment_details AS (
    SELECT 
        ws.ws_ship_mode_sk,
        sm.sm_type,
        COUNT(ws.ws_order_number) AS shipment_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_ship_mode_sk, sm.sm_type
)
SELECT
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_orders,
    hvc.total_spent,
    hvc.unique_addresses,
    sd.shipment_count,
    COALESCE(sd.total_profit, 0) AS total_profit,
    (CASE
        WHEN hvc.total_spent IS NULL THEN 'No Spend'
        WHEN hvc.total_spent > 1000 THEN 'High Roller'
        ELSE 'Regular Customer'
     END) AS customer_tier
FROM
    high_value_customers hvc
FULL OUTER JOIN shipment_details sd ON hvc.total_orders = sd.shipment_count
WHERE
    hvc.total_spent IS NOT NULL OR sd.total_profit IS NOT NULL
ORDER BY
    hvc.total_spent DESC NULLS LAST, 
    sd.total_profit DESC NULLS LAST
LIMIT 100;
