WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_net_paid > 100 THEN 'High'
            WHEN ws.ws_net_paid BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS Sales_Category
    FROM web_sales ws
    WHERE ws.ws_net_paid IS NOT NULL
),
AggregateData AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS Total_Net_Profit,
        COUNT(*) AS Sales_Count,
        AVG(sd.ws_sales_price) AS Avg_Sales_Price
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(a.Total_Net_Profit, 0) AS Total_Net_Profit,
        COALESCE(a.Sales_Count, 0) AS Sales_Count,
        COALESCE(a.Avg_Sales_Price, 0) AS Avg_Sales_Price,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(a.Total_Net_Profit, 0) ORDER BY i.i_item_desc) AS Row_Num
    FROM item i
    LEFT JOIN AggregateData a ON i.i_item_sk = a.ws_item_sk
),
RankedItems AS (
    SELECT 
        ii.i_item_desc,
        ii.Total_Net_Profit,
        ii.Sales_Count,
        ii.Avg_Sales_Price,
        ii.Row_Num,
        CASE 
            WHEN ii.Total_Net_Profit = 0 THEN 'No Sales'
            WHEN ii.Row_Num BETWEEN 1 AND 10 THEN 'Top 10 Items'
            ELSE 'Regular'
        END AS Ranking
    FROM ItemInfo ii
    WHERE ii.Total_Net_Profit IS NOT NULL AND ii.Total_Net_Profit <> 0
)
SELECT 
    ri.i_item_desc,
    ri.Total_Net_Profit,
    ri.Sales_Count,
    ri.Avg_Sales_Price,
    ri.Ranking,
    ROW_NUMBER() OVER (ORDER BY ri.Total_Net_Profit DESC) AS Overall_Rank
FROM RankedItems ri
WHERE ri.Sales_Count > 5
ORDER BY ri.Ranking, Overall_Rank
LIMIT 50;