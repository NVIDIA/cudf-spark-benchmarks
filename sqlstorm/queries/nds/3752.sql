
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(Ranked.ws_sales_price, 0) AS last_sales_price,
        COALESCE(Sales.total_net_paid, 0) AS total_net_sales
    FROM 
        item
    LEFT JOIN RankedSales Ranked ON item.i_item_sk = Ranked.ws_item_sk AND Ranked.rank = 1
    LEFT JOIN TotalSales Sales ON item.i_item_sk = Sales.ws_item_sk
    WHERE 
        item.i_current_price > 0
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    t.last_sales_price,
    t.total_net_sales,
    (CASE 
         WHEN t.total_net_sales > 1000 THEN 'High'
         WHEN t.total_net_sales BETWEEN 500 AND 1000 THEN 'Medium'
         ELSE 'Low'
     END) AS sales_category
FROM 
    TopItems t
ORDER BY 
    t.total_net_sales DESC
LIMIT 100;
