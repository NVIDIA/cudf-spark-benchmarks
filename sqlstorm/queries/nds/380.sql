
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_ship_date_sk IS NOT NULL
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        CustomerStats cs
        JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_count,
    SUM(hvc.total_spent) AS total_high_value_spent,
    MAX(rn) AS max_sales_rank
FROM
    HighValueCustomers hvc
    LEFT JOIN customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
    LEFT JOIN RankedSales rs ON hvc.c_customer_sk = rs.ws_item_sk
GROUP BY
    ca.ca_city, ca.ca_state
ORDER BY
    total_high_value_spent DESC
LIMIT 10;
