
WITH  cte_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
cte_combined AS (
    SELECT 
        inv.inv_item_sk,
        COALESCE(cte.total_sales, 0) AS total_sales,
        COALESCE(cte.total_orders, 0) AS total_orders,
        (SELECT COUNT(*) FROM store_sales WHERE ss_item_sk = inv.inv_item_sk) AS total_store_sales
    FROM inventory inv
    LEFT JOIN cte_sales cte ON inv.inv_item_sk = cte.ws_item_sk
),
cte_income AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS resident_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM household_demographics hd
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN customer c ON c.c_current_hdemo_sk = cd.cd_demo_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    cb.inv_item_sk,
    cb.total_sales,
    cb.total_orders,
    ci.resident_count,
    ci.total_purchase_estimate,
    CASE 
        WHEN total_orders = 0 THEN 'No Sales' 
        WHEN total_orders < 5 THEN 'Few Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM cte_combined cb
JOIN cte_income ci ON cb.inv_item_sk = ci.hd_income_band_sk
WHERE (cb.total_sales > 1000 OR cb.total_store_sales > 500)
  AND (cb.total_sales IS NOT NULL AND cb.total_orders IS NOT NULL)
  AND ci.resident_count > 10
ORDER BY cb.total_sales DESC
LIMIT 50 OFFSET 25;
