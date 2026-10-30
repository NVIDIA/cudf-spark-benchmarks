
WITH ranked_returns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM store_returns
    GROUP BY sr_item_sk
),
popular_items AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price) > (SELECT AVG(ws_sales_price) FROM web_sales)
),
highest_income_demo AS (
    SELECT 
        hd_income_band_sk,
        MAX(hd_buy_potential) AS max_buy_potential
    FROM household_demographics
    WHERE hd_buy_potential IS NOT NULL
    GROUP BY hd_income_band_sk
),
combined_metrics AS (
    SELECT 
        p.p_item_sk,
        COALESCE(r.total_returns, 0) AS returns,
        COALESCE(i.total_sales, 0) AS total_sales,
        COALESCE(d.max_buy_potential, 'None') AS max_buy_potential
    FROM promotion p
    LEFT JOIN ranked_returns r ON p.p_item_sk = r.sr_item_sk
    LEFT JOIN popular_items i ON p.p_item_sk = i.ws_item_sk
    LEFT JOIN highest_income_demo d ON p.p_item_sk = d.hd_income_band_sk
)
SELECT
    cm.p_item_sk,
    cm.returns,
    cm.total_sales,
    cm.max_buy_potential,
    CASE 
        WHEN cm.max_buy_potential IS NULL THEN 'Unknown'
        WHEN cm.total_sales > 0 AND cm.returns = 0 THEN 'High Demand'
        WHEN cm.total_sales = 0 AND cm.returns > 0 THEN 'High Returns'
        WHEN cm.returns > cm.total_sales THEN 'Return Heavy'
        ELSE 'Average'
    END AS performance_category
FROM combined_metrics cm
WHERE cm.returns > (SELECT AVG(returns) FROM combined_metrics)
   OR cm.total_sales < (SELECT AVG(total_sales) FROM combined_metrics)
ORDER BY cm.returns DESC NULLS LAST, cm.total_sales ASC;
