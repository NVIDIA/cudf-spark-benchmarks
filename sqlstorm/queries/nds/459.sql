
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rnk
    FROM 
        customer_sales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)
),
store_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(si.total_quantity, 0) AS quantity_available
    FROM 
        item i
        LEFT JOIN store_inventory si ON i.i_item_sk = si.inv_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    hvc.total_orders,
    id.i_item_desc,
    id.i_current_price,
    id.quantity_available,
    CASE 
        WHEN id.quantity_available < 10 THEN 'Low Stock' 
        WHEN id.quantity_available BETWEEN 10 AND 50 THEN 'Moderate Stock' 
        ELSE 'In Stock' 
    END AS stock_status
FROM 
    high_value_customers hvc
    CROSS JOIN item_details id
WHERE 
    hvc.rnk <= 10
ORDER BY 
    hvc.total_spent DESC, id.i_current_price ASC;
