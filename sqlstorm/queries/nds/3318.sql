
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_marital_status
    FROM RankedCustomers rc
    WHERE rc.rank_by_estimate <= 10
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        sd.total_sales_quantity,
        sd.total_net_profit
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    id.i_product_name,
    id.i_category,
    COALESCE(id.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(id.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN id.total_net_profit > 500 THEN 'High Profit'
        WHEN id.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Other'
    END AS sales_category
FROM HighValueCustomers hvc
LEFT JOIN ItemDetails id ON hvc.c_customer_sk = id.i_item_sk
WHERE (hvc.cd_marital_status = 'M' OR hvc.cd_marital_status IS NULL)
AND (id.total_sales_quantity IS NOT NULL OR id.total_sales_quantity > 10)
ORDER BY hvc.c_customer_sk, id.i_product_name;
