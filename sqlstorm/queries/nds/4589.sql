WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY 
        ws_item_sk
),
promotion_summary AS (
    SELECT 
        ws_item_sk,
        MAX(p.p_discount_active) AS is_discount_active
    FROM 
        web_sales ws
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        ws_item_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit,
        ps.is_discount_active,
        RANK() OVER (PARTITION BY ps.is_discount_active ORDER BY ss.total_profit DESC) AS profit_rank
    FROM 
        sales_summary ss
    JOIN 
        promotion_summary ps ON ss.ws_item_sk = ps.ws_item_sk
)
SELECT 
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    r.total_profit,
    r.is_discount_active
FROM 
    ranked_sales r
WHERE 
    r.profit_rank <= 10 
    AND r.is_discount_active = 'Y'
ORDER BY 
    r.total_profit DESC;