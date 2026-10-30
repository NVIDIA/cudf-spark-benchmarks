
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
),
HighSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price * ws_quantity) AS total_sales_value
    FROM 
        RankedSales
    WHERE 
        sales_rank = 1
    GROUP BY 
        ws_item_sk
),
SalesAndItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        hs.total_quantity_sold,
        hs.total_sales_value,
        COALESCE(sm.sm_type, 'Unknown') AS shipping_type
    FROM 
        item i
    LEFT JOIN 
        HighSales hs ON i.i_item_sk = hs.ws_item_sk
    LEFT JOIN 
        store s ON hs.ws_item_sk = s.s_store_sk
    LEFT JOIN 
        ship_mode sm ON s.s_store_sk = sm.sm_ship_mode_sk
)
SELECT 
    sd.i_item_id,
    sd.i_product_name,
    sd.total_quantity_sold,
    sd.total_sales_value,
    CONCAT('Total Sold: ', sd.total_quantity_sold, ', Total Revenue: $', ROUND(sd.total_sales_value, 2)) AS sales_summary
FROM 
    SalesAndItemDetails sd
WHERE 
    sd.total_sales_value IS NOT NULL
ORDER BY 
    sd.total_sales_value DESC
LIMIT 10;
