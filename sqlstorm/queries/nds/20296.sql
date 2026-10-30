
WITH  sales_growth AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_sold_date_sk, ws_item_sk
), item_ranks AS (
    SELECT 
        sg.ws_item_sk,
        sg.total_sales,
        LEAD(sg.total_sales) OVER (PARTITION BY sg.ws_item_sk ORDER BY sg.ws_sold_date_sk) AS next_total_sales,
        CASE 
            WHEN sg.total_sales IS NULL THEN 'No Sales'
            WHEN sg.total_sales < COALESCE(LEAD(sg.total_sales) OVER (PARTITION BY sg.ws_item_sk ORDER BY sg.ws_sold_date_sk), 0) THEN 'Growth'
            ELSE 'Decline or No Growth'
        END AS sales_trend
    FROM sales_growth sg
), combined_info AS (
    SELECT 
        ir.ws_item_sk,
        ir.total_sales,
        ir.sales_trend,
        CONCAT('Item #', ir.ws_item_sk, ' has a total sales of ', COALESCE(ir.total_sales, 0), ' with a trend of ', ir.sales_trend) AS item_summary
    FROM item_ranks ir
)
SELECT 
    ci.item_summary,
    COUNT(DISTINCT ci.ws_item_sk) AS item_count,
    AVG(COALESCE(ci.total_sales, 0)) AS avg_sales,
    COUNT(*) FILTER (WHERE ci.sales_trend = 'Growth') AS growth_count,
    MAX(ci.total_sales) FILTER (WHERE ci.sales_trend = 'Decline or No Growth') AS max_decline_sales
FROM combined_info ci
LEFT JOIN date_dim dd ON ci.ws_item_sk = dd.d_date_sk
WHERE dd.d_year = 2020
GROUP BY ci.item_summary
HAVING MAX(ci.total_sales) IS NOT NULL
ORDER BY avg_sales DESC
LIMIT 10;
