
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
)
SELECT 
    d.d_date AS sales_date, 
    i.i_item_id, 
    sd.total_quantity, 
    sd.total_sales
FROM 
    SalesData sd
JOIN 
    date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    sales_date, 
    total_quantity DESC;
