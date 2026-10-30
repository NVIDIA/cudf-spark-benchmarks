
WITH  sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_returns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_value,
        SUM(CASE WHEN sr_return_quantity = 0 THEN 1 ELSE 0 END) AS zero_quantity_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
detailed_analysis AS (
    SELECT
        ss.ws_item_sk,
        COALESCE(ss.total_quantity, 0) AS sold_quantity,
        COALESCE(ss.total_sales, 0) AS total_sold,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS return_value,
        COALESCE(cr.zero_quantity_returns, 0) AS returns_with_zero_quantity,
        (COALESCE(ss.total_sales, 0) - COALESCE(cr.total_return_value, 0)) AS net_sales_value,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) = 0 THEN 'N/A' 
            WHEN COALESCE(cr.total_returns, 0) > 0 THEN 
                ROUND((COALESCE(cr.total_returns, 0) / NULLIF(ss.total_quantity, 0)) * 100, 2) || '%' 
            ELSE '0%'
        END AS return_rate
    FROM sales_summary ss
    FULL OUTER JOIN customer_returns cr ON ss.ws_item_sk = cr.sr_item_sk
)
SELECT 
    da.ws_item_sk,
    da.sold_quantity,
    da.total_sold,
    da.total_returns,
    da.return_value,
    da.returns_with_zero_quantity,
    da.net_sales_value,
    da.return_rate
FROM detailed_analysis da
WHERE da.return_rate NOT LIKE 'N/A'
AND (da.net_sales_value > 1000 OR da.return_rate > '10%')
ORDER BY da.net_sales_value DESC, da.sold_quantity DESC
LIMIT 50;
