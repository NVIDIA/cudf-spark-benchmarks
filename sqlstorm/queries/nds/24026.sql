WITH SalesData AS (
    SELECT 
        ws.ws_item_sk AS Item_SK, 
        SUM(ws.ws_quantity) AS Total_Quantity,
        SUM(ws.ws_net_profit) AS Total_Net_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS Profit_Rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
TopProfitItems AS (
    SELECT 
        Item_SK, 
        Total_Quantity, 
        Total_Net_Profit, 
        Total_Orders
    FROM 
        SalesData
    WHERE 
        Profit_Rank <= 10
),
StoreSales AS (
    SELECT 
        ss.ss_item_sk AS Item_SK,
        SUM(ss.ss_quantity) AS Store_Quantity,
        SUM(ss.ss_net_profit) AS Store_Net_Profit
    FROM 
        store_sales ss
    JOIN 
        item ii ON ss.ss_item_sk = ii.i_item_sk
    GROUP BY 
        ss.ss_item_sk
),
CombinedSales AS (
    SELECT 
        t.Item_SK,
        COALESCE(s.Store_Quantity, 0) AS Store_Quantity,
        COALESCE(t.Total_Quantity, 0) AS Web_Quantity,
        (COALESCE(s.Store_Quantity, 0) + COALESCE(t.Total_Quantity, 0)) AS Combined_Quantity,
        (COALESCE(s.Store_Net_Profit, 0) + COALESCE(t.Total_Net_Profit, 0)) AS Combined_Net_Profit
    FROM 
        TopProfitItems t
    LEFT JOIN 
        StoreSales s ON t.Item_SK = s.Item_SK
)
SELECT 
    c.Item_SK, 
    c.Combined_Quantity, 
    c.Combined_Net_Profit,
    CASE 
        WHEN c.Combined_Net_Profit > 1000 THEN 'High Profit'
        WHEN c.Combined_Net_Profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit' 
    END AS Profit_Category,
    REPLACE(CONCAT('Item SK: ', c.Item_SK, ' has a combined profit of ', c.Combined_Net_Profit, ' and quantity of ', c.Combined_Quantity), ' ', '-') AS Summary
FROM 
    CombinedSales c
WHERE 
    c.Combined_Quantity IS NOT NULL 
ORDER BY 
    c.Combined_Net_Profit DESC, 
    c.Combined_Quantity ASC;