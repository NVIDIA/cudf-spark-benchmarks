
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_per_item
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 1000
), 
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(SUM(cs_quantity), 0) AS catalog_quantity,
        COALESCE(SUM(ss_quantity), 0) AS store_quantity
    FROM 
        item
    LEFT JOIN 
        catalog_sales cs ON i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i_item_sk = ss.ss_item_sk
    GROUP BY 
        i_item_sk, i_item_desc, i_current_price
), 
HighValueSales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS total_web_quantity,
        COALESCE(i.catalog_quantity, 0) AS catalog_quantity,
        COALESCE(i.store_quantity, 0) AS store_quantity,
        i.i_item_desc,
        i.i_current_price
    FROM 
        SalesSummary s
    FULL OUTER JOIN 
        ItemDetails i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.rank_per_item = 1 OR s.rank_per_item IS NULL
)
SELECT 
    h.total_web_quantity,
    h.catalog_quantity,
    h.store_quantity,
    h.i_item_desc,
    h.i_current_price,
    CASE 
        WHEN h.total_web_quantity > 0 THEN 'Web'
        WHEN h.catalog_quantity > 0 THEN 'Catalog'
        ELSE 'Store'
    END AS highest_sales_channel
FROM 
    HighValueSales h
WHERE 
    (h.total_web_quantity IS NOT NULL OR h.catalog_quantity IS NOT NULL OR h.store_quantity IS NOT NULL)
ORDER BY 
    h.total_web_quantity DESC, h.catalog_quantity DESC, h.store_quantity DESC;
