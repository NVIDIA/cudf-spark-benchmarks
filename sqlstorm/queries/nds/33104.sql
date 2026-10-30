
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM catalog_sales
    GROUP BY cs_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(s.total_sales, 0) AS total_sales_amount,
    CONCAT('Item: ', i.i_item_desc, ' sold a total of ', COALESCE(s.total_quantity, 0),
           ' units for a total of $', COALESCE(s.total_sales, 0)) AS sales_summary
FROM item i
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales
    FROM SalesCTE
    GROUP BY ws_item_sk
) s ON i.i_item_sk = s.ws_item_sk
WHERE 
    COALESCE(s.total_quantity, 0) > 100
    OR i.i_current_price > 20.00
ORDER BY total_sales_amount DESC
LIMIT 10;
