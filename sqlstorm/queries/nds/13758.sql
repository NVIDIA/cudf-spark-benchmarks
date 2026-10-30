WITH sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459545 AND 2459610 
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id, 
    sd.total_quantity, 
    sd.total_sales 
FROM 
    sales_data sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;