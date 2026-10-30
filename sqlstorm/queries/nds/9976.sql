
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
      AND cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk, 
        ri.total_quantity, 
        ri.total_net_profit,
        i.i_item_desc, 
        i.i_current_price,
        i.i_brand
    FROM RankedSales ri
    JOIN item i ON ri.ws_item_sk = i.i_item_sk
    WHERE ri.rank <= 10
)
SELECT 
    ti.i_item_desc,
    ti.i_brand,
    ti.total_quantity AS quantity_sold,
    ti.total_net_profit AS net_profit,
    ROUND((ti.total_net_profit / NULLIF(ti.total_quantity, 0)), 2) AS average_profit_per_item
FROM TopItems ti
ORDER BY ti.total_net_profit DESC;
