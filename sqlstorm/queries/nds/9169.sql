
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS item_rank
    FROM 
        sales_summary AS ss
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    i.i_item_desc,
    c.c_first_name,
    c.c_last_name,
    a.ca_city
FROM 
    top_items AS ti
JOIN 
    item AS i ON ti.ws_item_sk = i.i_item_sk
JOIN 
    web_sales AS ws ON ws.ws_item_sk = ti.ws_item_sk
JOIN 
    customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    ti.item_rank <= 10
ORDER BY 
    ti.total_sales DESC;
