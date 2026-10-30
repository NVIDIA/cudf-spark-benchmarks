
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
inventory_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        inv.inv_quantity_on_hand
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE
        inv.inv_quantity_on_hand > 0
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_item_sk,
        ws.ws_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
)
SELECT 
    a.i_item_id,
    COALESCE(b.total_sales, 0) AS total_sales,
    COALESCE(b.total_orders, 0) AS total_orders,
    COALESCE(c.c_first_name, 'Unknown') AS customer_first_name,
    COALESCE(c.c_last_name, 'Unknown') AS customer_last_name,
    d.inv_quantity_on_hand
FROM 
    inventory_details d
LEFT JOIN 
    ranked_sales b ON d.i_item_sk = b.ws_item_sk AND b.sales_rank = 1
LEFT JOIN 
    customer_sales c ON d.i_item_sk = c.ws_item_sk
JOIN 
    item a ON d.i_item_sk = a.i_item_sk
WHERE 
    d.inv_quantity_on_hand < 50
ORDER BY 
    total_sales DESC, 
    d.inv_quantity_on_hand ASC;
