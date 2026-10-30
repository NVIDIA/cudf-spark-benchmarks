
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
), 
InventoryInfo AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
), 
SalesSummary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price < (SELECT AVG(ws.ws_sales_price) FROM web_sales ws)
    GROUP BY 
        cs.cs_item_sk
    HAVING 
        SUM(cs.cs_ext_sales_price) > 1000
)

SELECT 
    COALESCE(item.i_item_id, 'Unknown Item') AS item_identifier,
    COALESCE(SUM(r.ws_sales_price), 0) AS total_web_sales,
    COALESCE(i.total_quantity, 0) AS total_inventory,
    COALESCE(ss.total_sales, 0) AS total_catalog_sales,
    CASE 
        WHEN SUM(r.ws_sales_price) IS NULL THEN 'No Data'
        WHEN SUM(r.ws_sales_price) > 1000 THEN 'High Performer'
        ELSE 'Standard Performer'
    END AS performance_category
FROM 
    RankedSales r
FULL OUTER JOIN 
    item ON r.ws_item_sk = item.i_item_sk
LEFT JOIN 
    InventoryInfo i ON r.ws_item_sk = i.inv_item_sk
LEFT JOIN 
    SalesSummary ss ON r.ws_item_sk = ss.cs_item_sk
WHERE 
    (item.i_rec_start_date IS NULL OR item.i_rec_end_date IS NULL) 
    AND (item.i_current_price BETWEEN 10 AND 50 OR item.i_brand LIKE 'Brand X%')
GROUP BY 
    item.i_item_id, i.total_quantity, ss.total_sales
HAVING 
    COALESCE(SUM(r.ws_sales_price), 0) > 500
ORDER BY 
    performance_category DESC, total_web_sales DESC
LIMIT 10;
