
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 
        AND ws_net_paid_inc_tax IS NOT NULL
),
customer_stats AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer 
    JOIN 
        web_sales ON c_customer_sk = ws_bill_customer_sk
    WHERE 
        c_birth_month = 5 OR c_birth_month IS NULL
    GROUP BY 
        c_customer_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 10000 THEN 'VIP' 
            ELSE 'Regular' 
        END AS customer_tier
    FROM 
        customer_stats cs
    WHERE 
        cs.order_count > 5
),
promotions_rank AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (ORDER BY COUNT(ws_order_number) DESC) AS promo_rank
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
    HAVING 
        SUM(ws_net_paid_inc_tax) > 5000
),
item_inventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
complex_sales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price <= (SELECT AVG(i_current_price) FROM item) 
        AND ss.ss_ticket_number IS NOT NULL
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.customer_tier,
    ci.total_inventory,
    ir.total_sales,
    ir.avg_profit
FROM 
    high_value_customers hvc
LEFT JOIN 
    item_inventory ci ON hvc.c_customer_sk = ci.inv_item_sk
JOIN 
    complex_sales ir ON hvc.c_customer_sk = ir.ss_item_sk
WHERE 
    (hvc.order_count > (SELECT AVG(order_count) FROM customer_stats) 
     OR hvc.total_spent IS NULL)
    AND hvc.c_customer_sk NOT IN (SELECT DISTINCT cs.c_customer_sk FROM customer_stats cs WHERE cs.order_count < 3)
ORDER BY 
    hvc.total_spent DESC, 
    hvc.customer_tier, 
    ci.total_inventory
