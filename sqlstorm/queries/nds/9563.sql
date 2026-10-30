
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        ri.total_profit,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        RANK() OVER (ORDER BY ri.total_sales DESC) AS item_rank
    FROM RankedSales ri
    JOIN item i ON ri.ws_item_sk = i.i_item_sk
)
SELECT
    ti.item_rank,
    ti.i_item_desc,
    ti.i_brand,
    ti.i_category,
    ti.total_quantity,
    ti.total_sales,
    ti.total_profit
FROM TopItems ti
WHERE ti.item_rank <= 10
ORDER BY ti.total_sales DESC;
