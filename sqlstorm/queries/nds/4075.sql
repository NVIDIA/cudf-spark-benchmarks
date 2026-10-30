
WITH CustomerData AS (
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
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate > 10000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customerData c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    WHERE 
        c.rn <= 10
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    hvc.full_name,
    hvc.cd_gender,
    hvc.customer_value,
    COALESCE(sd.total_profit, 0) AS total_profit,
    sd.total_orders
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    SalesData sd ON hvc.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    hvc.cd_gender IS NOT NULL
ORDER BY 
    total_profit DESC, full_name ASC
LIMIT 50 OFFSET 0;
