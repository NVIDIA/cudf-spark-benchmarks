
WITH  customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_quantity,
        cp.total_spent
    FROM 
        customer_purchases cp
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM customer_purchases)
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold,
        RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    ti.i_product_name,
    ti.total_sold
FROM 
    high_value_customers hvc
JOIN 
    top_items ti ON hvc.c_customer_sk = ti.i_item_sk
WHERE 
    ti.item_rank <= 10
ORDER BY 
    hvc.total_spent DESC, ti.total_sold DESC;
