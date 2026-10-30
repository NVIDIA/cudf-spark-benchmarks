
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
), 
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate
    FROM
        CustomerStats cs
    WHERE
        cs.rn <= 10
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(sd.total_profit, 0) = 0 THEN 'No Sales'
        WHEN sd.total_profit > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category
FROM
    TopCustomers tc
LEFT JOIN SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
WHERE
    (tc.cd_gender = 'F' AND COALESCE(sd.total_profit, 0) > 500) OR 
    (tc.cd_gender = 'M' AND COALESCE(sd.total_profit, 0) > 1000)
ORDER BY 
    tc.cd_gender, sd.total_profit DESC;
