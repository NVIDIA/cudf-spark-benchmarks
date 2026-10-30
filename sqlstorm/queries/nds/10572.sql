WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451544 AND 2451546 
    GROUP BY 
        ws_item_sk
), 
ItemData AS (
    SELECT 
        i_item_sk, 
        i_product_name, 
        i_current_price 
    FROM 
        item
)
SELECT 
    id.i_product_name, 
    sd.total_quantity, 
    sd.total_sales, 
    id.i_current_price,
    (sd.total_sales - (sd.total_quantity * id.i_current_price)) AS profit
FROM 
    SalesData sd
JOIN 
    ItemData id ON sd.ws_item_sk = id.i_item_sk
ORDER BY 
    profit DESC
LIMIT 10;