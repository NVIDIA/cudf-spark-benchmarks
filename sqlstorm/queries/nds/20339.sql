
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        row_number() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
        AND ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_profit) AS max_profit,
        MIN(ws.ws_net_profit) AS min_profit
    FROM 
        inventory inv
    LEFT JOIN 
        web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    WHERE 
        inv.inv_quantity_on_hand > 0
    GROUP BY 
        inv.inv_item_sk
),
PromotionalSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
        COUNT(ws.ws_order_number) AS promotional_orders
    FROM 
        web_sales ws 
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ca.ca_address_id,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ss.total_orders) AS total_sales_orders,
    AVG(ss.avg_sales_price) AS avg_selling_price,
    COALESCE(SUM(ps.total_ext_sales_price), 0) AS total_promotional_sales,
    MAX(ss.max_profit) AS highest_profit,
    AVG(CASE WHEN ss.max_profit > 0 THEN ss.max_profit ELSE NULL END) AS avg_high_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesSummary ss ON ss.inv_item_sk IN (
        SELECT ws_item_sk FROM RankedSales WHERE rank <= 5
    )
LEFT JOIN 
    PromotionalSales ps ON ps.ws_item_sk = ss.inv_item_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (c.c_birth_year IS NULL OR c.c_birth_year < 1980)
GROUP BY 
    ca.ca_address_id
HAVING 
    SUM(ss.total_orders) > 10
ORDER BY 
    customer_count DESC, total_promotional_sales DESC;
