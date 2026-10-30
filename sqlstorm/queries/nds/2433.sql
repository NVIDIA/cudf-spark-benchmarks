
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number
),

promotion_details AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        rr.r_reason_desc AS returned_reason
    FROM 
        promotion p
    LEFT JOIN 
        reason rr ON rr.r_reason_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
)

SELECT 
    ss.ws_item_sk, 
    ss.total_quantity,
    ss.total_net_profit,
    ss.total_discount,
    pd.p_promo_name,
    pd.returned_reason,
    ROW_NUMBER() OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.total_net_profit DESC) AS rank
FROM 
    sales_summary ss
LEFT JOIN 
    promotion_details pd ON ss.ws_item_sk = pd.p_promo_sk
WHERE 
    ss.total_net_profit > 0
    AND (ss.total_quantity > 10 OR ss.total_discount > 0)
ORDER BY 
    ss.total_net_profit DESC, 
    rank
LIMIT 100;

