
WITH  
    ItemSales AS (
        SELECT 
            ws_item_sk,
            SUM(ws_quantity) AS total_quantity,
            SUM(ws_sales_price) AS total_sales_price
        FROM web_sales
        GROUP BY ws_item_sk
    ),
    StoreSales AS (
        SELECT 
            ss_item_sk, 
            SUM(ss_quantity) AS total_quantity,
            SUM(ss_sales_price) AS total_sales_price
        FROM store_sales
        GROUP BY ss_item_sk
    ),
    TotalSales AS (
        SELECT 
            COALESCE(ws.ws_item_sk, ss.ss_item_sk) AS i_item_sk,
            COALESCE(ws.total_quantity, 0) AS web_total_quantity,
            COALESCE(ss.total_quantity, 0) AS store_total_quantity,
            COALESCE(ws.total_sales_price, 0) AS web_total_sales_price,
            COALESCE(ss.total_sales_price, 0) AS store_total_sales_price,
            (COALESCE(ws.total_quantity, 0) + COALESCE(ss.total_quantity, 0)) AS overall_quantity,
            (COALESCE(ws.total_sales_price, 0) + COALESCE(ss.total_sales_price, 0)) AS overall_sales_price
        FROM ItemSales ws
        FULL OUTER JOIN StoreSales ss ON ws.ws_item_sk = ss.ss_item_sk
    )
SELECT 
    item.i_item_id,
    item.i_item_desc,
    total.web_total_quantity,
    total.store_total_quantity,
    total.overall_quantity,
    total.web_total_sales_price,
    total.store_total_sales_price,
    total.overall_sales_price,
    ranking.rank
FROM item
JOIN TotalSales total ON item.i_item_sk = total.i_item_sk
LEFT JOIN (
    SELECT 
        i_item_sk,
        DENSE_RANK() OVER (ORDER BY overall_sales_price DESC) AS rank
    FROM TotalSales
) ranking ON total.i_item_sk = ranking.i_item_sk
WHERE 
    (total.web_total_quantity > 100 OR total.store_total_quantity > 100) 
    AND total.overall_sales_price > 5000
ORDER BY total.overall_sales_price DESC
LIMIT 10;
