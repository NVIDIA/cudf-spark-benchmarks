
WITH RankedSales AS (
    SELECT 
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS revenue_rank
    FROM web_sales
    GROUP BY ws_ship_customer_sk, ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ra.total_quantity,
        ra.total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN RankedSales ra ON c.c_customer_sk = ra.ws_ship_customer_sk
    WHERE ra.revenue_rank <= 10
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    ti.i_item_id,
    ti.i_product_name,
    ti.item_rank,
    cs.total_quantity,
    cs.total_net_profit
FROM CustomerSummary cs
JOIN TopItems ti ON cs.total_quantity > 100 AND ti.item_rank <= 5
ORDER BY cs.total_net_profit DESC;
