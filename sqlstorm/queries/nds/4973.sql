
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2500 AND 2600
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
TopCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cds.total_orders,
        cds.total_net_profit
    FROM CustomerDetails cd
    LEFT JOIN SalesSummary cds ON cd.c_customer_sk = cds.ws_bill_customer_sk
    WHERE cd.rn <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_orders, 0) AS order_count,
    COALESCE(tc.total_net_profit, 0) AS net_profit,
    CASE 
        WHEN tc.total_net_profit > 1000 THEN 'High Value'
        WHEN tc.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    (SELECT COUNT(DISTINCT ws_item_sk) 
     FROM web_sales 
     WHERE ws_bill_customer_sk = tc.c_customer_sk) AS distinct_purchased_items
FROM TopCustomers tc
ORDER BY net_profit DESC
LIMIT 20;
