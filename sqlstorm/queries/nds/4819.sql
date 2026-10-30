WITH sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_ship_date_sk >= 2450000 
    GROUP BY ws_ship_date_sk, ws_item_sk
),
return_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    GROUP BY wr_item_sk
),
combined_sales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_loss, 0)) AS net_sales,
        ss.average_profit
    FROM (SELECT DISTINCT ws_item_sk FROM web_sales) s
    LEFT JOIN sales_summary ss ON s.ws_item_sk = ss.ws_item_sk
    LEFT JOIN return_summary rs ON s.ws_item_sk = rs.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    combined.total_sales,
    combined.total_returns,
    combined.net_sales,
    combined.average_profit,
    CASE 
        WHEN combined.net_sales > 1000 THEN 'High Performer'
        WHEN combined.net_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    ROW_NUMBER() OVER (ORDER BY combined.net_sales DESC) AS performance_rank
FROM item i
JOIN combined_sales combined ON i.i_item_sk = combined.ws_item_sk
WHERE (combined.net_sales > 0 OR combined.total_returns > 0)
ORDER BY combined.net_sales DESC, i.i_item_id
LIMIT 100;