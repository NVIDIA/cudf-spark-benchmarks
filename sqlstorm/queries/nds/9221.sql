
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), high_sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        i.i_item_desc,
        i.i_brand,
        c.c_first_name,
        c.c_last_name 
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    JOIN 
        web_sales ws ON r.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    hs.ws_item_sk,
    hs.total_quantity,
    hs.total_sales,
    hs.i_item_desc,
    hs.i_brand,
    CONCAT(hs.c_first_name, ' ', hs.c_last_name) AS customer_name
FROM 
    high_sales hs
ORDER BY 
    hs.total_sales DESC;
