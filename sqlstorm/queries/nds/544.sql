
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
promotion_summary AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS average_discount
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_start_date_sk < p.p_end_date_sk
    GROUP BY 
        p.p_promo_sk
),
high_performing_items AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_profit,
        ps.total_sales
    FROM 
        ranked_sales r
    JOIN 
        promotion_summary ps ON r.ws_item_sk = ps.p_promo_sk
    WHERE 
        r.rank <= 10 AND ps.total_orders > 5
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    h.total_quantity,
    h.total_net_profit,
    h.total_sales,
    COALESCE(NULLIF(i.i_current_price, 0), AVG(i.i_current_price) OVER ()) AS adjusted_price
FROM 
    item i
JOIN 
    high_performing_items h ON i.i_item_sk = h.ws_item_sk
LEFT JOIN 
    customer c ON h.total_quantity > c.c_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
ORDER BY 
    h.total_net_profit DESC, adjusted_price ASC
LIMIT 50;
