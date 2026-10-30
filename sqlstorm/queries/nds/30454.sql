
WITH  SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS Total_Sold,
           ROW_NUMBER() OVER (ORDER BY SUM(ws_quantity) DESC) AS Rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2452500  
    GROUP BY ws_item_sk
), RankedSales AS (
    SELECT ss_item_sk,
           SUM(ss_quantity) AS Store_Total_Sold,
           ROW_NUMBER() OVER (ORDER BY SUM(ss_quantity) DESC) AS Store_Rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2452500  
    GROUP BY ss_item_sk
), CombinedSales AS (
    SELECT COALESCE(ws.ws_item_sk, ss.ss_item_sk) AS item_sk,
           COALESCE(ws.Total_Sold, 0) AS Web_Sales,
           COALESCE(ss.Store_Total_Sold, 0) AS Store_Sales,
           COALESCE(ws.Total_Sold, 0) + COALESCE(ss.Store_Total_Sold, 0) AS Total_Sales
    FROM SalesCTE ws
    FULL OUTER JOIN RankedSales ss ON ws.ws_item_sk = ss.ss_item_sk
)
SELECT i.i_item_id,
       i.i_item_desc,
       cs.Web_Sales,
       cs.Store_Sales,
       cs.Total_Sales,
       CASE WHEN cs.Total_Sales > 0 THEN (cs.Web_Sales * 100.0 / cs.Total_Sales) ELSE NULL END AS Web_Sales_Percentage,
       CASE
           WHEN cs.Total_Sales BETWEEN 0 AND 100 THEN 'Low Sales'
           WHEN cs.Total_Sales BETWEEN 101 AND 500 THEN 'Moderate Sales'
           ELSE 'High Sales' 
       END AS Sales_Category
FROM item i
JOIN CombinedSales cs ON i.i_item_sk = cs.item_sk
WHERE i.i_current_price IS NOT NULL
ORDER BY cs.Total_Sales DESC
LIMIT 10;
