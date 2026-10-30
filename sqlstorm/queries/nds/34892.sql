
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
), 
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_ext_sales_price) AS avg_order_value,
        MAX(ws.ws_ext_sales_price) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    cs.max_order_value,
    COALESCE(si.totalInventory, 0) AS total_inventory,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    customer c
LEFT JOIN 
    customer_stats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN (
        SELECT 
            inv.inv_item_sk,
            SUM(inv.inv_quantity_on_hand) AS totalInventory
        FROM 
            inventory inv
        GROUP BY 
            inv.inv_item_sk
    ) si ON si.inv_item_sk IN (SELECT DISTINCT sd.ws_item_sk FROM sales_data sd WHERE sd.rn = 1)
LEFT JOIN (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
) sd ON sd.ws_item_sk IN (SELECT DISTINCT sd2.ws_item_sk FROM sales_data sd2 WHERE sd2.rn = 1)
WHERE 
    cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
