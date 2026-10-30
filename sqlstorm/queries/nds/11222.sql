
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_product_name,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount
FROM 
    sales_data sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
