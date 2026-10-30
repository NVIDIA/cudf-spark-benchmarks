
WITH  sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    GROUP BY cs_item_sk
),
top_items AS (
    SELECT 
        cs_item_sk AS ss_item_sk, 
        total_sales, 
        order_count
    FROM sales_summary
    WHERE sales_rank <= 10
),
return_summary AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_amount) AS total_return,
        COUNT(cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_item_sk
),
net_profit AS (
    SELECT 
        ti.ss_item_sk,
        (ti.total_sales - COALESCE(rs.total_return, 0)) AS net_sales_profit,
        CASE 
            WHEN rs.return_count IS NOT NULL THEN 'Has Returns'
            ELSE 'No Returns'
        END AS return_status
    FROM top_items ti
    LEFT JOIN return_summary rs ON ti.ss_item_sk = rs.cr_item_sk
)
SELECT 
    i.i_item_id,
    np.net_sales_profit,
    np.return_status,
    CASE 
        WHEN np.net_sales_profit > 1000 THEN 'High Performer'
        WHEN np.net_sales_profit > 500 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    ROW_NUMBER() OVER (ORDER BY np.net_sales_profit DESC) AS rank_by_profit
FROM net_profit np
JOIN item i ON np.ss_item_sk = i.i_item_sk
WHERE (np.net_sales_profit IS NOT NULL OR np.return_status = 'No Returns')
AND (i.i_current_price * 1.1 > 100 OR i.i_brand = 'Brand X')
ORDER BY np.net_sales_profit DESC, performance_category ASC
LIMIT 20;
