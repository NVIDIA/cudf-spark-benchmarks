
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2451000
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_net_profit) AS average_profit
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
    HAVING SUM(ws.ws_quantity) > 100
),
FinalResults AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_profit,
        ti.i_item_desc,
        ti.total_quantity_sold,
        ti.average_profit
    FROM CustomerStats cs
    JOIN TopItems ti ON cs.order_count > 10
)
SELECT 
    DISTINCT fr.c_customer_sk,
    fr.order_count,
    fr.total_profit,
    fr.i_item_desc,
    fr.total_quantity_sold,
    fr.average_profit,
    CASE 
        WHEN fr.total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM FinalResults fr
WHERE fr.average_profit > 50
ORDER BY fr.total_profit DESC
LIMIT 100;
