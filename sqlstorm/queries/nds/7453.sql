
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SD.total_quantity, 0) AS total_quantity,
        COALESCE(SD.total_sales, 0) AS total_sales,
        COALESCE(SD.total_profit, 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        SalesData SD ON i.i_item_sk = SD.ws_item_sk
),
TopItems AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        id.total_quantity,
        id.total_sales,
        id.total_profit,
        DENSE_RANK() OVER (ORDER BY id.total_profit DESC) AS item_rank
    FROM 
        ItemDetails id
)
SELECT 
    t.item_rank,
    t.i_item_sk,
    t.i_item_desc,
    t.i_current_price,
    t.total_quantity,
    t.total_sales,
    t.total_profit
FROM 
    TopItems t
WHERE 
    t.item_rank <= 10
ORDER BY 
    t.item_rank;
