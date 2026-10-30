
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    sd.ws_sold_date_sk,
    id.i_item_desc,
    id.i_current_price,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount,
    sd.total_profit,
    CONCAT(id.c_first_name, ' ', id.c_last_name) AS customer_name
FROM 
    sales_data sd
JOIN 
    item_details id ON sd.ws_item_sk = id.i_item_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
