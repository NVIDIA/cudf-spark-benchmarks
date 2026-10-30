
WITH  sales_info AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_retention AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_net_paid) AS max_order_value,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
item_out_of_stock AS (
    SELECT 
        i.i_item_sk,
        (SELECT MAX(inv.inv_quantity_on_hand) 
         FROM inventory inv 
         WHERE inv.inv_item_sk = i.i_item_sk) AS max_quantity
    FROM 
        item i
    WHERE 
        i.i_rec_end_date IS NULL
),
address_info AS (
    SELECT 
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    ai.ca_state,
    ai.customer_count,
    si.total_quantity,
    si.total_net_paid,
    cr.order_count,
    cr.max_order_value,
    cr.avg_order_value,
    io.max_quantity
FROM 
    address_info ai
LEFT JOIN 
    sales_info si ON si.ws_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales)
LEFT JOIN 
    customer_retention cr ON cr.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
LEFT JOIN 
    item_out_of_stock io ON io.i_item_sk = (SELECT MIN(i_item_sk) FROM item)
WHERE 
    ai.customer_count > 50 
    AND (si.total_net_paid IS NOT NULL OR io.max_quantity IS NULL)
ORDER BY 
    ai.ca_state DESC, 
    cr.max_order_value DESC;
