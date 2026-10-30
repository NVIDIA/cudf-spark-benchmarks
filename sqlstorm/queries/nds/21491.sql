
WITH RecursiveInventory AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
), 
ZeroReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returned
    FROM web_returns
    GROUP BY wr_item_sk
    HAVING SUM(wr_return_quantity) = 0
), 
SalesComparison AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_web_sales,
        SUM(ws_sales_price) AS total_sales_value,
        ROW_NUMBER() OVER(ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    i.inv_item_sk,
    COALESCE(ws.total_web_sales, 0) AS web_sales,
    COALESCE(sr.total_returned, 0) AS total_web_returns,
    CASE 
        WHEN COALESCE(ws.total_web_sales, 0) = 0 THEN 'No Sales'
        ELSE 'Active'
    END AS sales_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = i.inv_item_sk) 
        THEN (SELECT SUM(ss_net_profit) FROM store_sales ss WHERE ss.ss_item_sk = i.inv_item_sk)
        ELSE NULL
    END AS total_store_profit
FROM RecursiveInventory i
LEFT JOIN SalesComparison ws ON i.inv_item_sk = ws.ws_item_sk
LEFT JOIN ZeroReturns sr ON i.inv_item_sk = sr.wr_item_sk
WHERE i.total_quantity > (
    SELECT AVG(total_quantity) 
    FROM RecursiveInventory
)
ORDER BY sales_status DESC, web_sales DESC;
