
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_sales)
),
top_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
),
item_promotions AS (
    SELECT 
        p.p_promo_name,
        p.p_discount_active,
        ti.ws_item_sk,
        SUM(ti.total_quantity_sold) AS total_sales
    FROM 
        top_items ti
    LEFT JOIN 
        promotion p ON ti.ws_item_sk = p.p_item_sk
    GROUP BY 
        p.p_promo_name, p.p_discount_active, ti.ws_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ip.p_promo_name,
    ip.total_sales,
    CASE 
        WHEN ip.p_discount_active = 'Y' THEN 'Active'
        ELSE 'Inactive'
    END AS promo_status
FROM 
    high_value_customers hvc
JOIN 
    item_promotions ip ON hvc.c_customer_sk = ip.ws_item_sk
JOIN 
    top_items ti ON ip.ws_item_sk = ti.ws_item_sk
WHERE 
    hvc.total_orders > (
        SELECT AVG(total_orders) FROM customer_sales
    )
ORDER BY 
    hvc.total_spent DESC, ti.total_quantity_sold DESC;
