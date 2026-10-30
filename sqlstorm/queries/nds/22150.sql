
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
SelectedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rank_profit <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(i.i_color, ''), 'N/A') AS item_color,
        COALESCE(i.i_brand, 'Unknown Brand') AS item_brand
    FROM 
        item i
)
SELECT 
    sa.ws_sold_date_sk,
    sa.total_quantity,
    sa.total_net_profit,
    id.i_item_desc,
    id.item_color,
    id.item_brand
FROM 
    SelectedSales sa
JOIN 
    ItemDetails id ON sa.ws_item_sk = id.i_item_sk
LEFT JOIN 
    (SELECT 
        DISTINCT sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returns
     FROM 
        store_returns
     GROUP BY 
        sr_customer_sk) sr ON sr.sr_customer_sk = sa.ws_item_sk
WHERE 
    sa.total_net_profit IS NOT NULL 
    AND sa.total_quantity > 10
ORDER BY 
    sa.total_net_profit DESC, sa.ws_sold_date_sk ASC
LIMIT 50;
