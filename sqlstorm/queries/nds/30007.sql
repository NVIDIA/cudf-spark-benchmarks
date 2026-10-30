WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451795 AND 2451875  
    GROUP BY ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        SUM(cs_ext_sales_price) 
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451795 AND 2451875
    GROUP BY cs_sold_date_sk, cs_item_sk
), 
SalesSummary AS (
    SELECT 
        ws.ws_item_sk AS item_sk,
        ws.total_sales + COALESCE(cs.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY COALESCE(cs.total_sales, 0) DESC) as rank
    FROM SalesCTE ws
    LEFT JOIN SalesCTE cs ON ws.ws_item_sk = cs.ws_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_sales, 0) AS total_sales,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    item i
LEFT JOIN 
    SalesSummary ss ON i.i_item_sk = ss.item_sk
WHERE 
    (i.i_current_price IS NOT NULL AND i.i_current_price > 0) 
    OR (ss.total_sales IS NOT NULL AND ss.total_sales > 500)
ORDER BY 
    total_sales DESC
LIMIT 10;