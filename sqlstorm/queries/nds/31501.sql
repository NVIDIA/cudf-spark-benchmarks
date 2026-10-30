
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rnk <= 10
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS rnk_inv
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    i.i_item_id,
    i.i_product_name,
    COALESCE(i.i_current_price, 0) AS current_price,
    COALESCE(iss.total_quantity, 0) AS inventory_quantity
FROM 
    top_customers tc
JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    inventory_summary iss ON i.i_item_sk = iss.inv_item_sk AND iss.rnk_inv = 1
WHERE 
    tc.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
ORDER BY 
    tc.total_sales DESC, tc.order_count ASC
LIMIT 5;
