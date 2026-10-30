
WITH CustomerPurchases AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT
        cp.c_customer_sk,
        cp.total_orders,
        cp.total_profit,
        CASE
            WHEN cp.total_profit > 1000 THEN 'High Value'
            WHEN cp.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM
        CustomerPurchases cp
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM
        customer_demographics cd
    INNER JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT
    hvc.c_customer_sk,
    hvc.total_orders,
    hvc.total_profit,
    hvc.customer_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating
FROM
    HighValueCustomers hvc
JOIN
    CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
WHERE
    hvc.total_orders > (SELECT AVG(total_orders) FROM CustomerPurchases)
    AND cd.cd_credit_rating IS NOT NULL
ORDER BY
    hvc.total_profit DESC
LIMIT 10;
