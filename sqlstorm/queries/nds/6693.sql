
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
        AND i.i_current_price > 10.00
        AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
top_items AS (
    SELECT 
        ris.ws_item_sk,
        ris.total_quantity,
        ris.total_sales,
        ris.sales_rank
    FROM 
        ranked_sales ris
    WHERE 
        ris.sales_rank <= 5
)
SELECT 
    ti.ws_item_sk,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
ORDER BY 
    ti.total_sales DESC;
