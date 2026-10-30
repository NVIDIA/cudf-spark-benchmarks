
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk, ws_ship_mode_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.i_current_price,
        COALESCE(SUM(ws.total_sales), 0) AS total_sales
    FROM 
        item
    LEFT JOIN 
        SalesCTE ws ON item.i_item_sk = ws.ws_item_sk AND ws.sales_rank <= 5
    GROUP BY 
        item.i_item_id, item.i_product_name, item.i_current_price
)
SELECT 
    ta.i_item_id,
    ta.i_product_name,
    ta.i_current_price,
    ta.total_sales,
    CASE 
        WHEN ta.total_sales > 100 THEN 'High Performer'
        WHEN ta.total_sales BETWEEN 50 AND 100 THEN 'Moderate Performer'
        ELSE 'Low Performer' 
    END AS performance_category,
    COALESCE(sh.sm_type, 'No Shipping Method') as shipping_method
FROM 
    TopSales ta 
LEFT JOIN 
    ship_mode sh ON sh.sm_ship_mode_sk IN (SELECT DISTINCT ws_ship_mode_sk FROM web_sales WHERE ws_ship_mode_sk IS NOT NULL)
ORDER BY 
    ta.total_sales DESC, 
    ta.i_product_name;
