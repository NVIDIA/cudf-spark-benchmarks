
WITH sales_summary AS (
    SELECT 
        CASE 
            WHEN ws_sales_price > 100 THEN 'Premium' 
            WHEN ws_sales_price BETWEEN 50 AND 100 THEN 'Midrange' 
            ELSE 'Budget' 
        END AS price_band,
        COUNT(ws_order_number) AS sales_count,
        SUM(ws_net_paid) AS total_revenue,
        SUM(ws_quantity) AS total_items_sold,
        AVG(ws_sales_price) AS avg_price_per_item
    FROM web_sales
    GROUP BY price_band
), demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    INNER JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    WHERE cd_purchase_estimate IS NOT NULL
    GROUP BY cd_gender
), warehouse_info AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory,
        CASE 
            WHEN w.w_warehouse_sq_ft > 10000 THEN 'Large'
            WHEN w.w_warehouse_sq_ft BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Small'
        END AS size_category
    FROM warehouse w
    LEFT JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_warehouse_sq_ft
)
SELECT 
    ss.price_band,
    ss.sales_count,
    ss.total_revenue,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ds.total_dependents,
    wi.w_warehouse_id,
    wi.w_warehouse_name,
    wi.total_inventory,
    wi.size_category
FROM sales_summary ss
JOIN demographic_summary ds ON (ss.sales_count > 100 AND ds.customer_count > 50)
FULL OUTER JOIN warehouse_info wi ON (wi.total_inventory > 500 AND ss.total_revenue IS NOT NULL)
WHERE (ss.total_revenue BETWEEN 1000 AND 10000 OR wi.size_category = 'Large')
ORDER BY ss.price_band, ds.avg_purchase_estimate DESC;
