
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(NULLIF(i_current_price, 0), 1) AS safe_price 
    FROM 
        item
),
TopProfitableItems AS (
    SELECT 
        ss.ws_sold_date_sk,
        id.i_item_sk,
        id.i_item_desc,
        ss.total_quantity,
        ss.total_profit,
        (ss.total_profit / id.safe_price) AS profit_margin
    FROM 
        SalesSummary ss
    JOIN 
        ItemDetails id ON ss.ws_item_sk = id.i_item_sk
    WHERE 
        ss.profit_rank <= 10
)
SELECT 
    t.d_date AS sale_date,
    ti.i_item_desc AS item_description,
    ti.total_quantity AS quantity_sold,
    ti.total_profit AS total_profit_generated,
    ti.profit_margin AS profit_margin
FROM 
    TopProfitableItems ti
JOIN 
    date_dim t ON ti.ws_sold_date_sk = t.d_date_sk
ORDER BY 
    t.d_date DESC, ti.total_profit DESC;
