
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    WHERE 
        ss.total_sales > 1000
),
customer_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count 
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN cr.total_returns > ss.total_sales THEN 'Higher Returns'
        ELSE 'Sales OK'
    END AS sales_status
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    customer_returns cr ON i.i_item_sk = cr.cr_item_sk
WHERE 
    EXISTS (SELECT 1 FROM top_items ti WHERE ti.ws_item_sk = i.i_item_sk AND ti.sales_rank <= 10)
ORDER BY 
    total_sales DESC, total_returns ASC;
