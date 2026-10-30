
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
HighProfitCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        total_profit
    FROM RankedSales
    WHERE profit_rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        bic.ws_bill_customer_sk AS c_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM web_sales ws
    JOIN HighProfitCustomers bic ON ws.ws_bill_customer_sk = bic.ws_bill_customer_sk
    GROUP BY bic.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    sd.total_quantity,
    sd.total_orders,
    sd.last_purchase_date,
    CASE 
        WHEN sd.last_purchase_date IS NULL THEN 'No Purchases'
        ELSE 'Active'
    END AS customer_status
FROM CustomerInfo ci
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.c_customer_sk
ORDER BY sd.total_quantity DESC, sd.total_orders DESC;
