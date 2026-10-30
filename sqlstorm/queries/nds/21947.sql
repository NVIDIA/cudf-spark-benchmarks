
WITH CTE_Promo AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_discount_active = 'Y' 
        AND p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_current_year = 'Y')
    GROUP BY 
        p.p_promo_name
),
CTE_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
        AND (c.c_first_name IS NOT NULL OR c.c_last_name IS NOT NULL) 
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(c.total_quantity, 0) AS total_quantity_sold,
    COALESCE(c.total_net_paid, 0.00) AS total_revenue,
    COALESCE(p.total_profit, 0.00) AS total_profit_from_promo
FROM 
    item i
LEFT JOIN 
    CTE_Sales c ON c.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CTE_Promo p ON p.p_promo_name LIKE '%' || i.i_item_desc || '%' 
WHERE 
    (i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)) 
    AND (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk) < 5
ORDER BY 
    total_revenue DESC, total_quantity_sold ASC
LIMIT 10;
