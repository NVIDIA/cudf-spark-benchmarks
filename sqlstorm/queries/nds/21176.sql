
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
inventory_check AS (
    SELECT 
        inv_item_sk,
        SUM(CASE WHEN inv_quantity_on_hand IS NULL THEN 0 ELSE inv_quantity_on_hand END) AS total_inventory,
        RANK() OVER (ORDER BY SUM(CASE WHEN inv_quantity_on_hand IS NULL THEN 0 ELSE inv_quantity_on_hand END) DESC) AS inventory_rank
    FROM inventory
    GROUP BY inv_item_sk
),
promo_summary AS (
    SELECT 
        p_item_sk, 
        COUNT(p_promo_id) AS promo_count,
        MIN(p_cost) AS min_cost
    FROM promotion
    GROUP BY p_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_sales,
    COALESCE(ic.total_inventory, 0) AS current_inventory,
    COALESCE(ps.promo_count, 0) AS active_promotions,
    COALESCE(ps.min_cost, 0) AS lowest_promo_cost,
    (ss.total_sales - COALESCE(ic.total_inventory, 0) * COALESCE(ps.min_cost, 0)) AS profit_margin
FROM sales_summary ss
LEFT JOIN inventory_check ic ON ss.ws_item_sk = ic.inv_item_sk
LEFT JOIN promo_summary ps ON ss.ws_item_sk = ps.p_item_sk
WHERE ss.sales_rank <= 10 
AND (COALESCE(ps.promo_count, 0) > 0 OR ps.min_cost IS NULL)
ORDER BY profit_margin DESC, total_sales DESC
LIMIT 50;
