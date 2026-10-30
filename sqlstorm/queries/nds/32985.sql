
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_order_number

    UNION ALL

    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk) AS sales_rank
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk, ss_ticket_number
), aggregated_sales AS (
    SELECT
        ss.ws_item_sk,
        COALESCE(SUM(ss.total_sales), 0) AS total_sales,
        COUNT(DISTINCT ss.ws_order_number) AS order_count,
        MAX(ss.sales_rank) AS max_sales_rank
    FROM sales_summary ss
    LEFT JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ss.ws_item_sk
)
SELECT
    a.ws_item_sk,
    a.total_sales,
    a.order_count,
    CASE
        WHEN a.total_sales > 1000 THEN 'High'
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COALESCE(ar.avg_return_amount, 0) AS avg_return_amount
FROM aggregated_sales a
LEFT JOIN (
    SELECT
        cr_item_sk,
        AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
) ar ON a.ws_item_sk = ar.cr_item_sk
WHERE a.order_count > 0
ORDER BY a.total_sales DESC
LIMIT 50;
