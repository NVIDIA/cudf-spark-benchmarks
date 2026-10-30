
WITH  sales_summary AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
customer_returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt_inc_tax) AS total_return,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
sales_comparison AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        COALESCE(cr.total_return, 0) AS total_return,
        (ss.total_sales - COALESCE(cr.total_return, 0)) AS net_sales,
        ss.order_count,
        (ss.total_sales - COALESCE(cr.total_return, 0)) / NULLIF(ss.total_sales, 0) AS return_rate
    FROM 
        sales_summary ss
    LEFT JOIN 
        customer_returns cr ON ss.ws_item_sk = cr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sc.total_sales,
    sc.total_return,
    sc.net_sales,
    sc.order_count,
    CASE 
        WHEN sc.return_rate IS NULL OR sc.return_rate < 0 THEN 'No sales'
        WHEN sc.return_rate < 0.1 THEN 'Low'
        WHEN sc.return_rate < 0.3 THEN 'Medium'
        ELSE 'High' 
    END AS return_status
FROM 
    sales_comparison sc
JOIN 
    item i ON sc.ws_item_sk = i.i_item_sk
WHERE 
    sc.net_sales > 0
ORDER BY 
    sc.net_sales DESC, i.i_item_id
LIMIT 100;
