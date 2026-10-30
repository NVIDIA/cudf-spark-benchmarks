
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank,
        ws.ws_sales_price,
        cc.cc_name,
        CASE 
            WHEN ws.ws_net_profit < 0 THEN 'Loss'
            WHEN ws.ws_net_profit = 0 THEN 'Break Even'
            ELSE 'Profit'
        END AS profit_status
    FROM 
        web_sales ws
    JOIN 
        call_center cc ON ws.ws_ship_customer_sk = cc.cc_call_center_sk
    WHERE 
        cc.cc_closed_date_sk IS NULL
),
total_sales AS (
    SELECT 
        r.rank, 
        SUM(r.ws_sales_price) AS total_sales_price,
        COUNT(*) AS total_orders
    FROM 
        ranked_sales r
    WHERE 
        r.rank <= 10 
    GROUP BY 
        r.rank
),
promotion_summary AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS orders_with_promo,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
    HAVING 
        SUM(ws.ws_net_profit) > 0
)
SELECT 
    ts.rank, 
    ts.total_sales_price, 
    ts.total_orders,
    ps.p_promo_name,
    ps.orders_with_promo,
    ps.total_profit
FROM 
    total_sales ts 
FULL OUTER JOIN 
    promotion_summary ps ON ts.rank = ps.orders_with_promo
WHERE 
    (ts.total_orders > 50 OR ps.total_profit IS NOT NULL)
ORDER BY 
    ts.rank ASC, ps.total_profit DESC
LIMIT 50;
