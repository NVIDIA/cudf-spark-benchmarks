
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS Total_Profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS Profit_Rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2022
    )
    GROUP BY ws_sold_date_sk, ws_item_sk
),
WarehouseInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS Total_Inventory
    FROM inventory
    GROUP BY inv_item_sk
),
TopProfitItems AS (
    SELECT 
        r.ws_item_sk,
        r.Total_Profit,
        w.Total_Inventory,
        r.Profit_Rank
    FROM RankedSales r
    JOIN WarehouseInventory w ON r.ws_item_sk = w.inv_item_sk
    WHERE r.Profit_Rank <= 5
),
CustomerReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS Total_Returns,
        SUM(sr_return_amt) AS Total_Return_Amount
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
)
SELECT 
    t.Item_ID,
    t.Total_Profit,
    COALESCE(c.Total_Returns, 0) AS Total_Returns,
    COALESCE(c.Total_Return_Amount, 0) AS Total_Return_Amount,
    CASE 
        WHEN t.Total_Profit IS NULL THEN 'No Sales Data'
        WHEN c.Total_Returns IS NULL OR c.Total_Returns = 0 THEN 'No Returns'
        ELSE 'Returns Available'
    END AS Return_Info
FROM (
    SELECT 
        i_item_id AS Item_ID,
        pi.Total_Profit,
        pi.Total_Inventory
    FROM item i
    JOIN TopProfitItems pi ON i.i_item_sk = pi.ws_item_sk
) t
LEFT JOIN CustomerReturnStats c ON t.Total_Profit IS NOT NULL OR t.Total_Profit > 0
ORDER BY t.Total_Profit DESC, COALESCE(c.Total_Return_Amount, 0) ASC;
