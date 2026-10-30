
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.total_profit = (SELECT MAX(total_profit) FROM SalesData)
),
OuterJoinData AS (
    SELECT 
        rc.c_customer_id,
        ti.total_quantity,
        COALESCE(ti.total_profit, 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY rc.PurchaseRank ORDER BY ti.total_profit DESC) AS ItemRank
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        TopProfitableItems ti ON rc.c_customer_sk = ti.ws_item_sk
)

SELECT 
    o.c_customer_id,
    o.total_quantity,
    o.total_profit,
    CASE 
        WHEN o.ItemRank <= 10 THEN 'Top Items'
        WHEN o.ItemRank IS NULL THEN 'No Purchases'
        ELSE 'Other Items'
    END AS ItemClassification,
    CASE 
        WHEN o.total_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Available'
    END AS ProfitStatus
FROM 
    OuterJoinData o
WHERE 
    o.total_quantity > 0
    OR (o.total_profit IS NOT NULL AND o.total_profit > 5000)
ORDER BY 
    o.total_profit DESC NULLS LAST;
