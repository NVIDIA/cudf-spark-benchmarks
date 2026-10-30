
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_customer_id
    FROM RankedCustomers rc
    WHERE rc.purchase_rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
TotalSales AS (
    SELECT 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 20.00)
)

SELECT 
    COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
    SUM(sd.total_sales) AS total_sales,
    ts.total_orders,
    ts.total_profit
FROM HighValueCustomers c
LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
CROSS JOIN TotalSales ts
GROUP BY c.c_customer_id, ts.total_orders, ts.total_profit
ORDER BY total_sales DESC
LIMIT 5;
