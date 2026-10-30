
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS Sales_Rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
Item_Details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SC.Total_Sales, 0) AS Total_Sales_Amount,
        CASE 
            WHEN COALESCE(SC.Total_Sales, 0) > 1000 THEN 'High' 
            ELSE 'Low' 
        END AS Sales_Category
    FROM 
        item i
    LEFT JOIN 
        Sales_CTE SC ON i.i_item_sk = SC.ws_item_sk
), 
Date_Summary AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ws_order_number) AS Order_Count,
        SUM(ws_ext_sales_price) AS Total_Sales_By_Year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    item.Total_Sales_Amount,
    item.Sales_Category,
    ds.Order_Count,
    ds.Total_Sales_By_Year
FROM 
    Item_Details item
LEFT JOIN 
    Date_Summary ds ON item.Total_Sales_Amount > 0
WHERE 
    item.Sales_Category = 'High'
    AND EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_item_sk = item.i_item_sk
        AND ss.ss_net_profit > (SELECT AVG(ss_net_profit) FROM store_sales)
    )
ORDER BY 
    item.Total_Sales_Amount DESC
LIMIT 10;
