WITH sales_summary AS (
    SELECT 
        ws.ws_web_site_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459600 AND 2459607 
      AND i.i_current_price > 10.00
      AND p.p_discount_active = 'Y'
    GROUP BY ws.ws_web_site_sk
),
top_sales AS (
    SELECT 
        w.w_warehouse_id,
        ss.total_orders,
        ss.total_quantity,
        ss.total_net_profit,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS net_profit_rank
    FROM sales_summary ss
    JOIN warehouse w ON ss.ws_web_site_sk = w.w_warehouse_sk
)
SELECT 
    w.w_warehouse_id,
    t.total_orders,
    t.total_quantity,
    t.total_net_profit
FROM top_sales t
JOIN warehouse w ON t.w_warehouse_id = w.w_warehouse_id
WHERE t.net_profit_rank <= 10 
ORDER BY t.total_net_profit DESC;