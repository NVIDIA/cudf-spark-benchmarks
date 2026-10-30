
WITH RankedSales AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        i.i_current_price > 0
        AND p.p_discount_active = 'Y'
    GROUP BY 
        ws.ws_web_page_sk
),
TopPages AS (
    SELECT 
        wp.wp_web_page_id,
        rp.total_profit,
        rp.total_orders
    FROM 
        RankedSales rp
    JOIN 
        web_page wp ON rp.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        rp.rank <= 10
)
SELECT 
    wp.wp_web_page_id,
    tp.total_profit,
    tp.total_orders,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopPages tp
JOIN 
    web_page wp ON tp.wp_web_page_id = wp.wp_web_page_id
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_email_address IS NOT NULL)
GROUP BY 
    wp.wp_web_page_id, tp.total_profit, tp.total_orders
ORDER BY 
    tp.total_profit DESC;
