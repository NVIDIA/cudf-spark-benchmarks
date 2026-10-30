
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
inventory_check AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
promotion_analysis AS (
    SELECT 
        p_item_sk,
        p_promo_name,
        COUNT(p_promo_sk) AS promo_count
    FROM 
        promotion
    WHERE 
        p_start_date_sk < (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-01')
        AND p_end_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        p_item_sk, p_promo_name
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.avg_net_paid, 0) AS avg_net_paid,
    COALESCE(ic.total_quantity, 0) AS total_inventory,
    pa.promo_count
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    inventory_check ic ON i.i_item_sk = ic.inv_item_sk
LEFT JOIN 
    promotion_analysis pa ON i.i_item_sk = pa.p_item_sk
WHERE 
    (ss.total_profit IS NOT NULL OR ic.total_quantity > 0 OR pa.promo_count > 0)
ORDER BY 
    total_profit DESC, total_sales DESC
LIMIT 100;
